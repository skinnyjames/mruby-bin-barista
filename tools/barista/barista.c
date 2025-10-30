#include <mruby.h>
#include <mruby/hash.h>
#include <mruby/compile.h>
#include <mruby/array.h>

#include <string.h>
#include <stdio.h>
#include "../../src/mrb_barista.h"

#define OPTPARSE_IMPLEMENTATION
#define OPTPARSE_API static
#include "optparse.h"

int main(int argc, char *argv[])
{
  mrb_state* mrb = mrb_open();
  mrb_mruby_bin_barista_gem_init(mrb);

  struct optparse options;
  optparse_init(&options, argv);
  char *arg;
  mrb_value ary = mrb_ary_new(mrb);
  while ((arg = optparse_arg(&options)))
  {
    mrb_ary_push(mrb, ary, mrb_str_new_cstr(mrb, arg));
  }

  FILE* file = fopen("Brewfile", "r");
  if (file == NULL)
  {
    fprintf(stderr, "Brewfile could not be loaded.\n");
    return 1;
  }

  mrb_value gemspec = mrb_load_file(mrb, file);
  if (mrb->exc) {
    mrb_print_error(mrb);
    return 1;
  }

  fclose(file);
  mrb_funcall(mrb, gemspec, "execute", 1, mrb_ary_join(mrb, ary, mrb_str_new_cstr(mrb, " ")));
  if (mrb->exc) {
    mrb_print_error(mrb);
    return 1;
  }
  mrb_mruby_bin_barista_gem_final(mrb);
  mrb_close(mrb);

  return 0;
}