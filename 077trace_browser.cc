:(before "End Primitive Recipe Declarations")
_BROWSE_TRACE,
:(before "End Primitive Recipe Numbers")
Recipe_number["$browse-trace"] = _BROWSE_TRACE;
:(before "End Primitive Recipe Implementations")
case _BROWSE_TRACE: {
  start_trace_browser();
  break;
}

:(before "End Globals")
set<long long int> Visible;
long long int Top_of_screen = 0;
long long int Last_printed_row = 0;

:(code)
void start_trace_browser() {
  if (!Trace_stream) return;
  cerr << "computing depth to display\n";
  long long int min_depth = 9999;
  for (long long int i = 0; i < SIZE(Trace_stream->past_lines); ++i) {
    trace_line& curr_line = Trace_stream->past_lines.at(i);
    if (curr_line.depth == 0) continue;
    if (curr_line.depth < min_depth) min_depth = curr_line.depth;
  }
  cerr << "depth is " << min_depth << '\n';
  cerr << "computing lines to display\n";
  for (long long int i = 0; i < SIZE(Trace_stream->past_lines); ++i) {
    if (Trace_stream->past_lines.at(i).depth == min_depth)
      Visible.insert(i);
  }
  tb_init();
  Display_row = Display_column = 0;
  struct tb_event event;
  while (true) {
    render();
    do {
      tb_poll_event(&event);
    } while (event.type != TB_EVENT_KEY);
    long long int key = event.key ? event.key : event.ch;
    if (key == 'q' || key == 'Q') break;
    if (key == 'j' || key == 'J') {
      if (Display_row < Last_printed_row) ++Display_row;
    }
    if (key == 'k' || key == 'K') {
      if (Display_row > 0) --Display_row;
    }
  }
  tb_shutdown();
}

void render() {
  long long int screen_row = 0, index = 0;
  for (screen_row = 0, index = Top_of_screen; screen_row < tb_height() && index < SIZE(Trace_stream->past_lines); ++screen_row, ++index) {
    // skip lines without depth for now
    while (Visible.find(index) == Visible.end()) {
      ++index;
      if (index >= SIZE(Trace_stream->past_lines)) goto done;
    }
    assert(index < SIZE(Trace_stream->past_lines));
    // render trace line at index
    trace_line& curr_line = Trace_stream->past_lines.at(index);
    ostringstream out;
    out << std::setw(4) << curr_line.depth << ' ' << curr_line.label << ": " << curr_line.contents;
    render_line(screen_row, out.str());
  }
done:
  // clear rest of screen
  Last_printed_row = screen_row-1;
  for (; screen_row < tb_height(); ++screen_row) {
    render_line(screen_row, "~");
  }
  // move cursor back to display row at the end
  tb_set_cursor(0, Display_row);
  tb_present();
}

void render_line(int screen_row, const string& s) {
  long long int col = 0;
  for (col = 0; col < tb_width() && col < SIZE(s); ++col) {
    char c = s.at(col);
    if (c == '\n') c = ';';  // replace newlines with semi-colons
    tb_change_cell(col, screen_row, c, TB_WHITE, TB_DEFAULT);
  }
  for (; col < tb_width(); ++col) {
    tb_change_cell(col, screen_row, ' ', TB_WHITE, TB_DEFAULT);
  }
}