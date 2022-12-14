find_program(ASCIIDOCTOR_EXE asciidoctor)
mark_as_advanced(ASCIIDOCTOR_EXE) # Don't show in CMake UIs

if(NOT ASCIIDOCTOR_EXE)
  message(WARNING "Could not find asciidoctor; documentation will not be generated")
else()
  function(generate_doc backend adoc_file output_file)
    get_filename_component(base_name "${adoc_file}" NAME_WE)
    add_custom_command(
      OUTPUT "${output_file}"
      COMMAND
        ${ASCIIDOCTOR_EXE}
          -o "${output_file}"
          -a revnumber="${CCACHE_VERSION}"
          -a icons=font
          -a toc=left
          -a sectanchors
          -a stylesheet="${CMAKE_CURRENT_SOURCE_DIR}/ccache-doc.css"
          -b "${backend}"
          "${CMAKE_SOURCE_DIR}/${adoc_file}"
      MAIN_DEPENDENCY "${CMAKE_SOURCE_DIR}/${adoc_file}"
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/ccache-doc.css"
    )
    set(doc_files "${doc_files}" "${output_file}" PARENT_SCOPE)
  endfunction()

  #
  # HTML documentation
  #
  generate_doc(html    LICENSE.adoc     LICENSE.html)
  generate_doc(html    doc/AUTHORS.adoc AUTHORS.html)
  generate_doc(html    doc/MANUAL.adoc  MANUAL.html)
  generate_doc(html    doc/NEWS.adoc    NEWS.html)
  add_custom_target(doc-html DEPENDS "${doc_files}")

  #
  # Man page
  #
  generate_doc(manpage doc/MANUAL.adoc ccache.1.tmp)
  add_custom_command(
    OUTPUT ccache.1
    # Convert monospace to bold since that's typically rendered better when
    # viewing the man page.
    COMMAND perl -pe "'s!\\\\f\\(CR(.*?)\\\\fP!\\\\fB\\1\\\\fP!g'" ccache.1.tmp >ccache.1
    MAIN_DEPENDENCY ccache.1.tmp
  )
  install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/ccache.1"
    DESTINATION "${CMAKE_INSTALL_MANDIR}/man1"
  )
  add_custom_target(doc-man-page DEPENDS ccache.1)

  add_custom_target(doc ALL DEPENDS doc-html doc-man-page)
endif()
