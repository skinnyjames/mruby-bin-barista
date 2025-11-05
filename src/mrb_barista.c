#ifndef MRUBY_BARISTA
#define MRUBY_BARISTA

#include <mruby.h>
#include <fcntl.h>
#include "platform.h"

mrb_value mrb_barista_os(mrb_state* mrb, mrb_value self)
{
  return mrb_str_new_cstr(mrb, platform_os_string(platform_detect_os()));
}

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

  struct RClass* barista = mrb_define_module(mrb, "Barista");
  mrb_define_class_method(mrb, barista, "os", mrb_barista_os, MRB_ARGS_NONE());
}

void mrb_mruby_bin_barista_gem_final(mrb_state* mrb)
{
}

#endif