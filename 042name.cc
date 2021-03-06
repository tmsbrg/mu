//: A big convenience high-level languages provide is the ability to name memory
//: locations. In mu, a transform called 'transform_names' provides this
//: convenience.

:(scenario transform_names)
recipe main [
  x:number <- copy 0
]
+name: assign x 1
+mem: storing 0 in location 1

:(scenarios transform)
:(scenario transform_names_fails_on_use_before_define)
% Hide_errors = true;
recipe main [
  x:number <- copy y:number
]
+error: main: use before set: y
# todo: detect conditional defines

:(after "End Type Modifying Transforms")
Transform.push_back(transform_names);  // idempotent

:(before "End Globals")
map<recipe_ordinal, map<string, long long int> > Name;
:(after "Clear Other State For Recently_added_recipes")
for (long long int i = 0; i < SIZE(Recently_added_recipes); ++i) {
  Name.erase(Recently_added_recipes.at(i));
}

:(code)
void transform_names(const recipe_ordinal r) {
  recipe& caller = get(Recipe, r);
  trace(9991, "transform") << "--- transform names for recipe " << caller.name << end();
//?   cerr << "--- transform names for recipe " << caller.name << '\n';
  bool names_used = false;
  bool numeric_locations_used = false;
  map<string, long long int>& names = Name[r];
  // store the indices 'used' so far in the map
  long long int& curr_idx = names[""];
  ++curr_idx;  // avoid using index 0, benign skip in some other cases
  for (long long int i = 0; i < SIZE(caller.steps); ++i) {
    instruction& inst = caller.steps.at(i);
    // End transform_names(inst) Special-cases
    // map names to addresses
    for (long long int in = 0; in < SIZE(inst.ingredients); ++in) {
      if (is_disqualified(inst.ingredients.at(in), inst, caller.name)) continue;
      if (is_numeric_location(inst.ingredients.at(in))) numeric_locations_used = true;
      if (is_named_location(inst.ingredients.at(in))) names_used = true;
      if (is_integer(inst.ingredients.at(in).name)) continue;
      if (!already_transformed(inst.ingredients.at(in), names)) {
        raise_error << maybe(caller.name) << "use before set: " << inst.ingredients.at(in).name << '\n' << end();
      }
      inst.ingredients.at(in).set_value(lookup_name(inst.ingredients.at(in), r));
    }
    for (long long int out = 0; out < SIZE(inst.products); ++out) {
      if (is_disqualified(inst.products.at(out), inst, caller.name)) continue;
      if (is_numeric_location(inst.products.at(out))) numeric_locations_used = true;
      if (is_named_location(inst.products.at(out))) names_used = true;
      if (is_integer(inst.products.at(out).name)) continue;
      if (names.find(inst.products.at(out).name) == names.end()) {
        trace(9993, "name") << "assign " << inst.products.at(out).name << " " << curr_idx << end();
        names[inst.products.at(out).name] = curr_idx;
        curr_idx += size_of(inst.products.at(out));
      }
      inst.products.at(out).set_value(lookup_name(inst.products.at(out), r));
    }
  }
  if (names_used && numeric_locations_used)
    raise_error << maybe(caller.name) << "mixing variable names and numeric addresses\n" << end();
}

bool is_disqualified(/*mutable*/ reagent& x, const instruction& inst, const string& recipe_name) {
  if (!x.type) {
    // End Null-type is_disqualified Exceptions
    raise_error << maybe(recipe_name) << "missing type for " << x.original_string << " in '" << inst.to_string() << "'\n" << end();
    return true;
  }
  if (is_raw(x)) return true;
  if (is_literal(x)) return true;
  // End is_disqualified Cases
  if (x.initialized) return true;
  return false;
}

bool already_transformed(const reagent& r, const map<string, long long int>& names) {
  return contains_key(names, r.name);
}

long long int lookup_name(const reagent& r, const recipe_ordinal default_recipe) {
  return Name[default_recipe][r.name];
}

type_ordinal skip_addresses(type_tree* type, const string& recipe_name) {
  type_ordinal address = get(Type_ordinal, "address");
  type_ordinal shared = get(Type_ordinal, "shared");
  for (; type; type = type->right) {
    if (type->value != address && type->value != shared)
      return type->value;
  }
  raise_error << maybe(recipe_name) << "expected a container" << '\n' << end();
  return -1;
}

int find_element_name(const type_ordinal t, const string& name, const string& recipe_name) {
  const type_info& container = get(Type, t);
  for (long long int i = 0; i < SIZE(container.element_names); ++i) {
    if (container.element_names.at(i) == name) return i;
  }
  raise_error << maybe(recipe_name) << "unknown element " << name << " in container " << get(Type, t).name << '\n' << end();
  return -1;
}

bool is_numeric_location(const reagent& x) {
  if (is_literal(x)) return false;
  if (is_raw(x)) return false;
  if (x.name == "0") return false;  // used for chaining lexical scopes
  return is_integer(x.name);
}

bool is_named_location(const reagent& x) {
  if (is_literal(x)) return false;
  if (is_raw(x)) return false;
  if (is_special_name(x.name)) return false;
  return !is_integer(x.name);
}

bool is_special_name(const string& s) {
  if (s == "_") return true;
  if (s == "0") return true;
  // End is_special_name Cases
  return false;
}

:(scenario transform_names_passes_dummy)
# _ is just a dummy result that never gets consumed
recipe main [
  _, x:number <- copy 0, 1
]
+name: assign x 1
-name: assign _ 1

//: an escape hatch to suppress name conversion that we'll use later
:(scenarios run)
:(scenario transform_names_passes_raw)
% Hide_errors = true;
recipe main [
  x:number/raw <- copy 0
]
-name: assign x 1
+error: can't write to location 0 in 'x:number/raw <- copy 0'

:(scenarios transform)
:(scenario transform_names_fails_when_mixing_names_and_numeric_locations)
% Hide_errors = true;
recipe main [
  x:number <- copy 1:number
]
+error: main: mixing variable names and numeric addresses

:(scenario transform_names_fails_when_mixing_names_and_numeric_locations_2)
% Hide_errors = true;
recipe main [
  x:number <- copy 1
  1:number <- copy x:number
]
+error: main: mixing variable names and numeric addresses

:(scenario transform_names_does_not_fail_when_mixing_names_and_raw_locations)
% Hide_errors = true;
recipe main [
  x:number <- copy 1:number/raw
]
-error: main: mixing variable names and numeric addresses
$error: 0

:(scenario transform_names_does_not_fail_when_mixing_names_and_literals)
% Hide_errors = true;
recipe main [
  x:number <- copy 1
]
-error: main: mixing variable names and numeric addresses
$error: 0

//:: Support element names for containers in 'get' and 'get-address'.

:(scenario transform_names_transforms_container_elements)
recipe main [
  p:address:point <- copy 0
  a:number <- get *p:address:point, y:offset
  b:number <- get *p:address:point, x:offset
]
+name: element y of type point is at offset 1
+name: element x of type point is at offset 0

:(before "End transform_names(inst) Special-cases")
// replace element names of containers with offsets
if (inst.name == "get" || inst.name == "get-address") {
  if (SIZE(inst.ingredients) != 2) {
    raise_error << maybe(get(Recipe, r).name) << "exactly 2 ingredients expected in '" << inst.to_string() << "'\n" << end();
    break;
  }
  if (!is_literal(inst.ingredients.at(1)))
    raise_error << maybe(get(Recipe, r).name) << "expected ingredient 1 of " << (inst.name == "get" ? "'get'" : "'get-address'") << " to have type 'offset'; got " << inst.ingredients.at(1).original_string << '\n' << end();
  if (inst.ingredients.at(1).name.find_first_not_of("0123456789") != string::npos) {
    // since first non-address in base type must be a container, we don't have to canonize
    type_ordinal base_type = skip_addresses(inst.ingredients.at(0).type, get(Recipe, r).name);
    if (contains_key(Type, base_type)) {  // otherwise we'll raise an error elsewhere
      inst.ingredients.at(1).set_value(find_element_name(base_type, inst.ingredients.at(1).name, get(Recipe, r).name));
      trace(9993, "name") << "element " << inst.ingredients.at(1).name << " of type " << get(Type, base_type).name << " is at offset " << no_scientific(inst.ingredients.at(1).value) << end();
    }
  }
}

//: this test is actually illegal so can't call run
:(scenarios transform)
:(scenario transform_names_handles_containers)
recipe main [
  a:point <- copy 0/unsafe
  b:number <- copy 0/unsafe
]
+name: assign a 1
+name: assign b 3

//:: Support variant names for exclusive containers in 'maybe-convert'.

:(scenarios run)
:(scenario transform_names_handles_exclusive_containers)
recipe main [
  12:number <- copy 1
  13:number <- copy 35
  14:number <- copy 36
  20:address:point <- maybe-convert 12:number-or-point/unsafe, p:variant
]
+name: variant p of type number-or-point has tag 1
+mem: storing 13 in location 20

:(before "End transform_names(inst) Special-cases")
// convert variant names of exclusive containers
if (inst.name == "maybe-convert") {
  if (SIZE(inst.ingredients) != 2) {
    raise_error << maybe(get(Recipe, r).name) << "exactly 2 ingredients expected in '" << inst.to_string() << "'\n" << end();
    break;
  }
  assert(is_literal(inst.ingredients.at(1)));
  if (inst.ingredients.at(1).name.find_first_not_of("0123456789") != string::npos) {
    // since first non-address in base type must be an exclusive container, we don't have to canonize
    type_ordinal base_type = skip_addresses(inst.ingredients.at(0).type, get(Recipe, r).name);
    if (contains_key(Type, base_type)) {  // otherwise we'll raise an error elsewhere
      inst.ingredients.at(1).set_value(find_element_name(base_type, inst.ingredients.at(1).name, get(Recipe, r).name));
      trace(9993, "name") << "variant " << inst.ingredients.at(1).name << " of type " << get(Type, base_type).name << " has tag " << no_scientific(inst.ingredients.at(1).value) << end();
    }
  }
}
