//: Arithmetic primitives

:(before "End Primitive Recipe Declarations")
ADD,
:(before "End Primitive Recipe Numbers")
Recipe_ordinal["add"] = ADD;
:(before "End Primitive Recipe Implementations")
case ADD: {
  double result = 0;
//?   if (!tb_is_active()) cerr << ingredients.at(1).at(0) << '\n'; //? 1
  for (long long int i = 0; i < SIZE(ingredients); ++i) {
    if (!scalar(ingredients.at(i))) {
      raise << current_recipe_name() << ": 'add' requires number ingredients, but got " << current_instruction().ingredients.at(i).original_string << '\n' << end();
      goto finish_instruction;
    }
    result += ingredients.at(i).at(0);
  }
  products.resize(1);
  products.at(0).push_back(result);
  break;
}

:(scenario add_literal)
recipe main [
  1:number <- add 23, 34
]
+mem: storing 57 in location 1

:(scenario add)
recipe main [
  1:number <- copy 23
  2:number <- copy 34
  3:number <- add 1:number, 2:number
]
+mem: storing 57 in location 3

:(scenario add_multiple)
recipe main [
  1:number <- add 3, 4, 5
]
+mem: storing 12 in location 1

:(before "End Primitive Recipe Declarations")
SUBTRACT,
:(before "End Primitive Recipe Numbers")
Recipe_ordinal["subtract"] = SUBTRACT;
:(before "End Primitive Recipe Implementations")
case SUBTRACT: {
  if (ingredients.empty()) {
    raise << current_recipe_name() << ": 'subtract' has no ingredients\n" << end();
    break;
  }
  if (!scalar(ingredients.at(0))) {
    raise << current_recipe_name() << ": 'subtract' requires number ingredients, but got " << current_instruction().ingredients.at(0).original_string << '\n' << end();
    goto finish_instruction;
  }
  double result = ingredients.at(0).at(0);
  for (long long int i = 1; i < SIZE(ingredients); ++i) {
    if (!scalar(ingredients.at(i))) {
      raise << current_recipe_name() << ": 'subtract' requires number ingredients, but got " << current_instruction().ingredients.at(i).original_string << '\n' << end();
      goto finish_instruction;
    }
    result -= ingredients.at(i).at(0);
  }
  products.resize(1);
  products.at(0).push_back(result);
  break;
}

:(scenario subtract_literal)
recipe main [
  1:number <- subtract 5, 2
]
+mem: storing 3 in location 1

:(scenario subtract)
recipe main [
  1:number <- copy 23
  2:number <- copy 34
  3:number <- subtract 1:number, 2:number
]
+mem: storing -11 in location 3

:(scenario subtract_multiple)
recipe main [
  1:number <- subtract 6, 3, 2
]
+mem: storing 1 in location 1

:(before "End Primitive Recipe Declarations")
MULTIPLY,
:(before "End Primitive Recipe Numbers")
Recipe_ordinal["multiply"] = MULTIPLY;
:(before "End Primitive Recipe Implementations")
case MULTIPLY: {
  double result = 1;
  for (long long int i = 0; i < SIZE(ingredients); ++i) {
    if (!scalar(ingredients.at(i))) {
      raise << current_recipe_name() << ": 'multiply' requires number ingredients, but got " << current_instruction().ingredients.at(i).original_string << '\n' << end();
      goto finish_instruction;
    }
    result *= ingredients.at(i).at(0);
  }
  products.resize(1);
  products.at(0).push_back(result);
  break;
}

:(scenario multiply_literal)
recipe main [
  1:number <- multiply 2, 3
]
+mem: storing 6 in location 1

:(scenario multiply)
recipe main [
  1:number <- copy 4
  2:number <- copy 6
  3:number <- multiply 1:number, 2:number
]
+mem: storing 24 in location 3

:(scenario multiply_multiple)
recipe main [
  1:number <- multiply 2, 3, 4
]
+mem: storing 24 in location 1

:(before "End Primitive Recipe Declarations")
DIVIDE,
:(before "End Primitive Recipe Numbers")
Recipe_ordinal["divide"] = DIVIDE;
:(before "End Primitive Recipe Implementations")
case DIVIDE: {
  if (ingredients.empty()) {
    raise << current_recipe_name() << ": 'divide' has no ingredients\n" << end();
    break;
  }
  if (!scalar(ingredients.at(0))) {
    raise << current_recipe_name() << ": 'divide' requires number ingredients, but got " << current_instruction().ingredients.at(0).original_string << '\n' << end();
    goto finish_instruction;
  }
  double result = ingredients.at(0).at(0);
  for (long long int i = 1; i < SIZE(ingredients); ++i) {
    if (!scalar(ingredients.at(i))) {
      raise << current_recipe_name() << ": 'divide' requires number ingredients, but got " << current_instruction().ingredients.at(i).original_string << '\n' << end();
      goto finish_instruction;
    }
    result /= ingredients.at(i).at(0);
  }
  products.resize(1);
  products.at(0).push_back(result);
  break;
}

:(scenario divide_literal)
recipe main [
  1:number <- divide 8, 2
]
+mem: storing 4 in location 1

:(scenario divide)
recipe main [
  1:number <- copy 27
  2:number <- copy 3
  3:number <- divide 1:number, 2:number
]
+mem: storing 9 in location 3

:(scenario divide_multiple)
recipe main [
  1:number <- divide 12, 3, 2
]
+mem: storing 2 in location 1

//: Integer division

:(before "End Primitive Recipe Declarations")
DIVIDE_WITH_REMAINDER,
:(before "End Primitive Recipe Numbers")
Recipe_ordinal["divide-with-remainder"] = DIVIDE_WITH_REMAINDER;
:(before "End Primitive Recipe Implementations")
case DIVIDE_WITH_REMAINDER: {
  products.resize(2);
  if (SIZE(ingredients) != 2) {
    raise << current_recipe_name() << ": 'divide-with-remainder' requires exactly two ingredients, but got '" << current_instruction().to_string() << "'\n" << end();
    break;
  }
  if (!scalar(ingredients.at(0)) || !scalar(ingredients.at(1))) {
    raise << current_recipe_name() << ": 'divide-with-remainder' requires number ingredients, but got '" << current_instruction().to_string() << "'\n" << end();
    goto finish_instruction;
  }
  long long int quotient = ingredients.at(0).at(0) / ingredients.at(1).at(0);
  long long int remainder = static_cast<long long int>(ingredients.at(0).at(0)) % static_cast<long long int>(ingredients.at(1).at(0));
  // very large integers will lose precision
  products.at(0).push_back(quotient);
  products.at(1).push_back(remainder);
  break;
}

:(scenario divide_with_remainder_literal)
recipe main [
  1:number, 2:number <- divide-with-remainder 9, 2
]
+mem: storing 4 in location 1
+mem: storing 1 in location 2

:(scenario divide_with_remainder)
recipe main [
  1:number <- copy 27
  2:number <- copy 11
  3:number, 4:number <- divide-with-remainder 1:number, 2:number
]
+mem: storing 2 in location 3
+mem: storing 5 in location 4

:(scenario divide_with_decimal_point)
recipe main [
  # todo: literal floats?
  1:number <- divide 5, 2
]
+mem: storing 2.5 in location 1

:(code)
inline bool scalar(const vector<long long int>& x) {
  return SIZE(x) == 1;
}
inline bool scalar(const vector<double>& x) {
  return SIZE(x) == 1;
}
