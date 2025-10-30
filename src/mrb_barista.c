#ifndef MRUBY_BARISTA
#define MRUBY_BARISTA

#include <mruby.h>
#include <fcntl.h>

mrb_value mrb_io_nonblock(mrb_state* mrb, mrb_value self)
{
  int fd = mrb_int(mrb, mrb_funcall(mrb, self, "fileno", 0, NULL));
  int flags = fcntl(fd, F_GETFL, 0);
  fcntl(fd, F_SETFL, flags | O_NONBLOCK);
  return mrb_nil_value();
}

void mrb_mruby_bin_barista_gem_init(mrb_state* mrb)
{
  struct RClass* ioclass = mrb_class_get(mrb, "IO");
  mrb_define_method(mrb, ioclass, "nonblock!", mrb_io_nonblock, MRB_ARGS_NONE());
}

void mrb_mruby_bin_barista_gem_final(mrb_state* mrb)
{
}

#endif