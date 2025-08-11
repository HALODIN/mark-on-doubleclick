
cmake_minimum_required(VERSION 3.16)
project(mark_on_doubleclick_eplugin_v4_5 C)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(PkgConfig REQUIRED)

pkg_check_modules(EVO_MAIL REQUIRED evolution-mail-3.0)
pkg_check_modules(GTK3     REQUIRED gtk+-3.0)
pkg_check_modules(GLIB     REQUIRED glib-2.0 gobject-2.0 gmodule-2.0)
pkg_check_modules(CAMEL    REQUIRED camel-1.2)

add_library(org-gnome-mark-on-doubleclick SHARED
  src/mark_on_doubleclick_eplugin.c
)

target_include_directories(org-gnome-mark-on-doubleclick PRIVATE
  ${EVO_MAIL_INCLUDE_DIRS} ${GTK3_INCLUDE_DIRS} ${GLIB_INCLUDE_DIRS} ${CAMEL_INCLUDE_DIRS}
)

target_compile_options(org-gnome-mark-on-doubleclick PRIVATE
  ${EVO_MAIL_CFLAGS_OTHER} ${GTK3_CFLAGS_OTHER} ${GLIB_CFLAGS_OTHER} ${CAMEL_CFLAGS_OTHER}
)

target_link_libraries(org-gnome-mark-on-doubleclick
  ${GTK3_LIBRARIES} ${GLIB_LIBRARIES}
)

set_target_properties(org-gnome-mark-on-doubleclick PROPERTIES
  OUTPUT_NAME "liborg-gnome-mark-on-doubleclick"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

include(GNUInstallDirs)

# Detect Evolution plugin dir; fallback to /usr/lib/evolution/plugins
execute_process(
  COMMAND sh -c "dpkg -L evolution | awk '/\\/evolution\\/plugins\\/.*\\.so$/ {print; exit}' | xargs dirname"
  OUTPUT_VARIABLE EVO_PLUGIN_LIBDIR
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT EVO_PLUGIN_LIBDIR)
  set(EVO_PLUGIN_LIBDIR "${CMAKE_INSTALL_FULL_LIBDIR}/evolution/plugins")
endif()

set(PLUGINDIR "${EVO_PLUGIN_LIBDIR}")
set(SOEXT ".so")
configure_file(
  data/org-gnome-mark-on-doubleclick.eplug.in
  ${CMAKE_CURRENT_BINARY_DIR}/org-gnome-mark-on-doubleclick.eplug
  @ONLY
)

install(TARGETS org-gnome-mark-on-doubleclick LIBRARY DESTINATION ${EVO_PLUGIN_LIBDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org-gnome-mark-on-doubleclick.eplug DESTINATION ${EVO_PLUGIN_LIBDIR})
