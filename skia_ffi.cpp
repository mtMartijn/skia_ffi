#include "skia_ffi.h"

#include <iostream>

#include "GrBackendSurface.h"
#include "GrContext.h"
#include "SkCanvas.h"
#include "SkSurface.h"

static GrContext* sContext = nullptr;
static SkSurface* sSurface = nullptr;
static SkCanvas* canvas = nullptr;

#define SK_COL(col) SkColorSetARGB(col.a * 0xFF, col.r * 0xFF, col.g * 0xFF, col.b * 0xFF)

struct path { SkPath obj; };
struct paint { SkPaint obj; };

void init_skia(int w, int h) {
  sContext = GrContext::MakeGL(nullptr).release();

  GrGLFramebufferInfo framebufferInfo;
  framebufferInfo.fFBOID = 0;  // assume default framebuffer
  GrBackendRenderTarget backendRenderTarget(w, h, 0, 0, kSkia8888_GrPixelConfig, framebufferInfo);

  sSurface = SkSurface::MakeFromBackendRenderTarget(sContext, backendRenderTarget,
      kBottomLeft_GrSurfaceOrigin,
      nullptr, nullptr).release();
  canvas = sSurface->getCanvas();   // We don't manage this pointer's lifetime.
}

void cleanup_skia() {
  delete sSurface;
  delete sContext;
}

// ======= SkCanvas ======= //

void clear(rgba color) {
  canvas->clear(SK_COL(color));
}

void flush() {
  canvas->flush();
}

void draw_point(point p, paint* pnt) {
  canvas->drawPoint(p.x, p.y, pnt->obj);
}

void draw_line(point start, point end, paint* pnt) {
  canvas->drawLine(start.x, start.y, end.x, end.y, pnt->obj);
}

void draw_arrow(point start, point dir, paint* pnt) {
  canvas->drawLine(start.x, start.y, start.x + dir.x, start.y + dir.y, pnt->obj);
}

void draw_rect(point corner, point size, float radius, paint* pnt) {
  auto rect = SkRect::MakeXYWH(corner.x, corner.y, size.x, size.y);
  canvas->drawRoundRect(rect, radius, radius, pnt->obj);
}

void draw_crect(point center, point size, float radius, paint* pnt) {
  auto rect = SkRect::MakeXYWH(center.x - size.x*0.5f, center.y - size.y*0.5f, size.x, size.y);
  canvas->drawRoundRect(rect, radius, radius, pnt->obj);
}

void draw_quad(point a, point b, float radius, paint* pnt) {
  auto rect = SkRect::MakeXYWH(a.x, a.y, b.x - a.x, b.y - a.y);
  canvas->drawRoundRect(rect, radius, radius, pnt->obj);
}

void draw_circle(point center, float radius, paint* pnt) {
  canvas->drawCircle(center.x, center.y, radius, pnt->obj);
}

void draw_oval(point center, point radius, paint* pnt) {
  auto oval = SkRect::MakeXYWH(center.x - radius.x*0.5f, center.y - radius.y*0.5f, radius.x, radius.y);
  canvas->drawOval(oval, pnt->obj);
}

void draw_path(path* s, paint* pnt) {
  canvas->drawPath(s->obj, pnt->obj);
}

void translate(point dir) {
  canvas->translate(dir.x, dir.y);
}

void rotate(float angle) {
  canvas->rotate(angle);
}

void scale(point size) {
  canvas->scale(size.x, size.y);
}

void skew(float sx, float sy) {
  canvas->skew(sx, sy);
}

void reset_matrix() { 
  canvas->resetMatrix();
}

// ======= SkPath ======= //

path* path_new() {
  return new path();
}

void path_delete(path* s) {
  delete s;
}

void path_reset(path* s) {
  s->obj.reset();
}

void path_rewind(path* s) {
  s->obj.rewind();
}

void path_close(path* s) {
  s->obj.close();
}

void path_move(path* s, point p) {
  s->obj.moveTo(p.x, p.y);
}

void path_line(path* s, point p) {
  s->obj.lineTo(p.x, p.y);
}

void path_quad(path* s, point a, point end) {
  s->obj.quadTo(a.x, a.y, end.x, end.y);
}

void path_cubic(path* s, point a1, point a2, point end) { 
  s->obj.cubicTo(a1.x, a1.y, a2.x, a2.y, end.x, end.y);
}

void path_conic(path* s, point a, point end, float weight) {
  s->obj.conicTo(a.x, a.y, end.x, end.y, weight);
}

// ======= SkPaint ======= //

paint* paint_new() {
  auto p = new paint();
  // Default:
  p->obj.setAntiAlias(true);
  p->obj.setColor(SK_ColorWHITE);
  p->obj.setStyle(SkPaint::kStroke_Style);
  p->obj.setStrokeJoin(SkPaint::kRound_Join);
  p->obj.setStrokeCap(SkPaint::kRound_Cap);
  p->obj.setStrokeWidth(2.f);
  return p;
}

void paint_delete(paint* p) {
  delete p;
}

/* paint* new_stroke(rgba color, float w, cap c, join j) { */
/*   auto p = new paint(); */
/*   p->obj.setAntiAlias(true); */
/*   p->obj.setStyle(SkPaint::kStroke_Style); */
/*   p->obj.setColor(SK_COL(color)); */
/*   p->obj.setStrokeWidth(w); */
/*   switch(c) { */
/*     case butt_cap: p->obj.setStrokeCap(SkPaint::kButt_Cap); break; */
/*     case round_cap: p->obj.setStrokeCap(SkPaint::kRound_Cap); break; */
/*     case square_cap: p->obj.setStrokeCap(SkPaint::kSquare_Cap); break; */
/*   } */
/*   switch(j) { */
/*     case miter_join: p->obj.setStrokeJoin(SkPaint::kMiter_Join); break; */
/*     case round_join: p->obj.setStrokeJoin(SkPaint::kRound_Join); break; */
/*     case bevel_join: p->obj.setStrokeJoin(SkPaint::kBevel_Join); break; */
/*   } */
/*   return p; */
/* } */

/* paint* new_fill(rgba color) { */
/*   auto p = new paint(); */
/*   p->obj.setAntiAlias(true); */
/*   p->obj.setStyle(SkPaint::kFill_Style); */
/*   p->obj.setColor(SK_COL(color)); */
/*   return p; */
/* } */

void set_color(paint* p, rgba color) {
  p->obj.setColor(SK_COL(color));
}

void set_alpha(paint* p, float a) {
  p->obj.setAlpha(static_cast<U8CPU>(a));
}

void set_style(paint* p, style s) {
  switch(s) {
    case fill: p->obj.setStyle(SkPaint::kFill_Style); break;
    case stroke: p->obj.setStyle(SkPaint::kStroke_Style); break;
    case stroke_and_fill: p->obj.setStyle(SkPaint::kStrokeAndFill_Style); break;
  }
}

void set_stroke_join(paint* p, join j) {
  switch(j) {
    case miter_join: p->obj.setStrokeJoin(SkPaint::kMiter_Join); break;
    case round_join: p->obj.setStrokeJoin(SkPaint::kRound_Join); break;
    case bevel_join: p->obj.setStrokeJoin(SkPaint::kBevel_Join); break;
  }
}

void set_stroke_cap(paint* p, cap c) {
  switch(c) {
    case butt_cap: p->obj.setStrokeCap(SkPaint::kButt_Cap); break;
    case round_cap: p->obj.setStrokeCap(SkPaint::kRound_Cap); break;
    case square_cap: p->obj.setStrokeCap(SkPaint::kSquare_Cap); break;
  }
}

void set_stroke_width(paint* p, float w) { 
  p->obj.setStrokeWidth(w);
}

