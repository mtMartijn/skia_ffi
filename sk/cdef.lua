local ffi = require("ffi")

ffi.cdef[[
typedef struct { float x, y; } point;
typedef struct { float r, g, b, a; } rgba;
typedef struct path path;
typedef struct paint paint;

void flush();
void clear(rgba color);

void draw_point(point p, paint* pnt);
void draw_line(point start, point end, paint* pnt);
void draw_arrow(point start, point dir, paint* pnt);
void draw_rect(point corner, point size, float radius, paint* pnt);
void draw_crect(point center, point size, float radius, paint* pnt);
void draw_quad(point a, point b, float radius, paint* pnt);
void draw_circle(point center, float radius, paint* pnt);
void draw_oval(point center, point radius, paint* pnt);
void draw_path(path* s, paint* pnt);

void translate(point dir);
void rotate(float angle);
void scale(point size);
void skew(float sx, float sy);
void reset_matrix();

// ======= SkPath ======= //
path* path_new();
void path_delete(path* s);
void path_reset(path* s);
void path_rewind(path* s);
void path_close(path* s);
void path_move(path* s, point p);
void path_line(path* s, point p);
void path_quad(path* s, point a, point end);
void path_cubic(path* s, point a1, point a2, point end);
void path_conic(path* s, point a, point end, float weight);

// ======= SkPaint ======= //
paint* paint_new();
void paint_delete(paint* p);

typedef enum {
  fill,
  stroke,
  stroke_and_fill,
} style;

typedef enum {
  miter_join,
  round_join,
  bevel_join,
} join;

typedef enum {
  butt_cap,
  round_cap,
  square_cap,
} cap;

void set_color(paint* p, rgba color);
void set_alpha(paint* p, float a);
void set_style(paint* p, style s);
void set_stroke_join(paint* p, join j);
void set_stroke_cap(paint * p, cap c);
void set_stroke_width(paint* p, float w);
]]

return ffi.C
