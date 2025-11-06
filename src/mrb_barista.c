#ifndef MRUBY_BARISTA
#define MRUBY_BARISTA

#include <mruby.h>
#include "platform.h"

#if defined(PLATFORM_WIN32) || defined(__MINGW32__)
#include <winsock2.h>
#else
#include <fcntl.h>
#endif

mrb_value mrb_barista_os(mrb_state* mrb, mrb_value self)
{
  return mrb_str_new_cstr(mrb, platform_os_string(platform_detect_os()));
}
#if defined(PLATFORM_WIN32) || defined(__MINGW32__)
mrb_value mrb_io_nonblock(mrb_state* mrb, mrb_value self)
{
  u_long iMode = 1;
  int fd = mrb_int(mrb, mrb_funcall(mrb, self, "fileno", 0, NULL));
  ioctlsocket(fd, FIONBIO, &iMode);
  return mrb_nil_value();
}
#else
mrb_value mrb_io_nonblock(mrb_state* mrb, mrb_value self)
{
  int fd = mrb_int(mrb, mrb_funcall(mrb, self, "fileno", 0, NULL));
  int flags = fcntl(fd, F_GETFL, 0);
  fcntl(fd, F_SETFL, flags | O_NONBLOCK);
  return mrb_nil_value();
}
#endif

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