CLASS zcl_abapgit_oo_interface DEFINITION PUBLIC
  INHERITING FROM zcl_abapgit_oo_base.
  PUBLIC SECTION.
    METHODS:
      zif_abapgit_oo_object_fnc~create REDEFINITION,
      zif_abapgit_oo_object_fnc~get_includes REDEFINITION,
      zif_abapgit_oo_object_fnc~get_interface_properties REDEFINITION,
      zif_abapgit_oo_object_fnc~delete REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_abapgit_oo_interface IMPLEMENTATION.


  METHOD zif_abapgit_oo_object_fnc~create.
    DATA: lt_vseoattrib TYPE seoo_attributes_r.
    DATA lv_intkey TYPE seoclskey.
    FIELD-SYMBOLS: <lv_clsname> TYPE seoclsname.

    ASSIGN COMPONENT 'CLSNAME' OF STRUCTURE cg_properties TO <lv_clsname>.
    ASSERT sy-subrc = 0.

    lv_intkey = <lv_clsname>.

    lt_vseoattrib = convert_attrib_to_vseoattrib( iv_clsname    = <lv_clsname>
                                                  it_attributes = it_attributes ).

    CALL FUNCTION 'SEO_INTERFACE_DELETE_COMPLETE'
      EXPORTING
        intkey          = lv_intkey    " Interface
        genflag         = abap_false    " Generation Flag
        authority_check = abap_false " Execute authority check (suppress possible only for GENFLAG
        suppress_commit = abap_true    " No DB_COMMIT will be executed
        suppress_corr   = abap_true   " Suppress Corr-Insert and Corr-Check
        suppress_dialog = abap_true   " X = no user interaction
      EXCEPTIONS
        not_existing    = 1
        is_class        = 2
        db_error        = 3
        no_access       = 4
        other           = 5
        OTHERS          = 6.
    CASE  sy-subrc.
      WHEN 0.
        "expected. we successfully deleted the interface before creating it.
      WHEN 1.
        "not an issue. when the class is not present, the will be no issues with creating it
      WHEN OTHERS.
        zcx_abapgit_exception=>raise( |Error from SEO_INTERFACE_DELETE_COMPLETE. Subrc = { sy-subrc }| ).
    ENDCASE.

    CALL FUNCTION 'SEO_INTERFACE_CREATE_COMPLETE'
      EXPORTING
        devclass        = iv_package
        overwrite       = iv_overwrite
        suppress_dialog = abap_true
      CHANGING
        interface       = cg_properties
        attributes      = lt_vseoattrib
      EXCEPTIONS
        existing        = 1
        is_class        = 2
        db_error        = 3
        component_error = 4
        no_access       = 5
        other           = 6
        OTHERS          = 7.
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( |Error from SEO_INTERFACE_CREATE_COMPLETE. Subrc = { sy-subrc }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_abapgit_oo_object_fnc~delete.
    CALL FUNCTION 'SEO_INTERFACE_DELETE_COMPLETE'
      EXPORTING
        intkey       = is_deletion_key
      EXCEPTIONS
        not_existing = 1
        is_class     = 2
        db_error     = 3
        no_access    = 4
        other        = 5
        OTHERS       = 6.
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( |Error from SEO_INTERFACE_DELETE_COMPLETE. Subrc = { sy-subrc }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_abapgit_oo_object_fnc~get_includes.
    DATA lv_interface_name TYPE seoclsname.
    lv_interface_name = iv_object_name.
    APPEND cl_oo_classname_service=>get_interfacepool_name( lv_interface_name ) TO rt_includes.
  ENDMETHOD.


  METHOD zif_abapgit_oo_object_fnc~get_interface_properties.
    CALL FUNCTION 'SEO_CLIF_GET'
      EXPORTING
        cifkey       = is_interface_key
        version      = seoc_version_active
      IMPORTING
        interface    = rs_interface_properties
      EXCEPTIONS
        not_existing = 1
        deleted      = 2
        model_only   = 3
        OTHERS       = 4.
    IF sy-subrc = 1.
      RETURN. " in case only inactive version exists
    ELSEIF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( |Error from seo_clif_get. Subrc = { sy-subrc }| ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
