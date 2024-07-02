# This script sets two variables:
#
# - CCACHE_VERSION (version string)
# - CCACHE_VERSION_ORIGIN (archive or git)
#
# There are three main scenarios:
#
# 1. Building from a source code archive generated by "git archive", e.g. the
#    official source code archive or one downloaded directly from GitHub via
#    <https://github.com/ccache/ccache/archive/VERSION.tar.gz>. In this case the
#    version_info info string below will be substituted because of export-subst
#    in the .gitattributes file. The version will then be correct if VERSION
#    refers to a tagged commit. If the commit is not tagged the version will be
#    set to the commit hash instead.
# 2. Building from a source code archive not generated by "git archive" (i.e.,
#    version_info has not been substituted). In this case we fail the
#    configuration.
# 3. Building from a Git repository. In this case the version will be a proper
#    version if building a tagged commit, otherwise "branch.hash(+dirty)". In
#    case Git is not available, the version will be "unknown".
#
# CCACHE_VERSION_ORIGIN is set to "archive" in scenario 1 and "git" in scenario
# 3.

set(version_info "4c6181f7f93f8dad8106973aaf55475cddfd2730 HEAD, tag: v4.10.1, origin/HEAD, origin/4.10-maint, 4.10-maint")
set(CCACHE_VERSION "unknown")

if(version_info MATCHES "^([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])[0-9a-f]* (.*)")
  # Scenario 1.
  set(CCACHE_VERSION_ORIGIN archive)

  set(hash "${CMAKE_MATCH_1}")
  set(ref_names "${CMAKE_MATCH_2}")
  if(ref_names MATCHES "tag: v([^,]+)")
    # Tagged commit.
    set(CCACHE_VERSION "${CMAKE_MATCH_1}")
  else()
    # Untagged commit.
    set(CCACHE_VERSION "${hash}")
  endif()
elseif(EXISTS "${CMAKE_SOURCE_DIR}/.git")
  # Scenario 3.
  set(CCACHE_VERSION_ORIGIN git)

  find_package(Git QUIET)
  if(NOT GIT_FOUND)
    message(WARNING "Could not find git")
  else()
    macro(git)
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" ${ARGN}
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE git_stdout OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE git_stderr ERROR_STRIP_TRAILING_WHITESPACE)
    endmacro()

    git(describe --tags --abbrev=8 --dirty)
    if(git_stdout MATCHES "^v([^-]+)(-dirty)?$")
      set(CCACHE_VERSION "${CMAKE_MATCH_1}")
      if(NOT "${CMAKE_MATCH_2}" STREQUAL "")
        set(CCACHE_VERSION "${CCACHE_VERSION}+dirty")
      endif()
    elseif(git_stdout MATCHES "^v[^-]+-[0-9]+-g([0-9a-f]+)(-dirty)?$")
      set(hash "${CMAKE_MATCH_1}")
      set(dirty "${CMAKE_MATCH_2}")
      string(REPLACE "-" "+" dirty "${dirty}")

      git(rev-parse --abbrev-ref HEAD)
      set(branch "${git_stdout}")

      set(CCACHE_VERSION "${branch}.${hash}${dirty}")
    endif() # else: fail below
  endif()
endif()

if("${CCACHE_VERSION}" STREQUAL "unknown")
  # Scenario 2 or unexpected error.
  message(WARNING "Could not determine ccache version")
endif()

message(STATUS "Ccache version: ${CCACHE_VERSION}")
