"""
Converts the .xlsx template to .ods and adds the city search for LibreOffice Calc (scripts/city-picker.bas):
a ComboBox over the dy_pg_info pg_city column, filled from the Lookups sheet, and the macro bound to the sheet's
"Selection changed" event.

LibreOffice runs this itself as a Python script (scripts/export-template.js starts it headless): its bundled
Python may only be launched by LibreOffice, so a standalone Python cannot drive it. Paths come from the environment:
MAKE_ODS_SRC (.xlsx), MAKE_ODS_OUT (.ods), MAKE_ODS_BAS (the macro), MAKE_ODS_RESULT ("ok" or the error is written here).
"""

import os
import traceback
from pathlib import Path

import uno
from com.sun.star.awt import Point, Size
from com.sun.star.beans import PropertyValue

SHEET = "dy_pg_info"
BOX = "CityPicker"
MODULE = "CityPicker"


def props(**kw):
    out = []
    for k, v in kw.items():
        p = PropertyValue()
        p.Name, p.Value = k, v
        out.append(p)
    return tuple(out)


def add_city_picker(doc, bas_source):
    sheet = doc.Sheets.getByName(SHEET)
    page = sheet.DrawPage
    for i in reversed(range(page.Count)):  # running it again replaces the box
        s = page.getByIndex(i)
        if s.supportsService("com.sun.star.drawing.ControlShape") and s.Control.Name == BOX:
            page.remove(s)

    model = doc.createInstance("com.sun.star.form.component.ComboBox")
    model.Name = BOX
    model.Dropdown = False  # the list shows under the text as you type, no click needed
    model.Autocomplete = True  # AutoFill
    model.EnableVisible = False  # hidden until a city cell is selected
    model.Printable = False
    shape = doc.createInstance("com.sun.star.drawing.ControlShape")
    shape.Position = Point(0, 0)
    shape.Size = Size(5000, 5000)
    shape.Control = model
    page.add(shape)

    libs = doc.BasicLibraries
    if not libs.hasByName("Standard"):
        libs.createLibrary("Standard")
    lib = libs.getByName("Standard")
    if lib.hasByName(MODULE):
        lib.removeByName(MODULE)
    lib.insertByName(MODULE, bas_source)

    url = f"vnd.sun.star.script:Standard.{MODULE}.OnSelect?language=Basic&location=document"
    event = uno.Any("[]com.sun.star.beans.PropertyValue", props(EventType="Script", Script=url))
    uno.invoke(sheet.Events, "replaceByName", ("OnSelect", event))

    # Open with the form live, not in design mode, so the box works straight away.
    doc.ApplyFormDesignMode = False


def main(*_):
    desktop = XSCRIPTCONTEXT.getDesktop()  # noqa: F821 (provided by LibreOffice)
    result = Path(os.environ["MAKE_ODS_RESULT"])
    try:
        src, out = Path(os.environ["MAKE_ODS_SRC"]), Path(os.environ["MAKE_ODS_OUT"])
        doc = desktop.loadComponentFromURL(src.as_uri(), "_blank", 0, props(Hidden=True))
        if doc is None:
            raise RuntimeError(f"LibreOffice could not open {src}")
        try:
            if not doc.Sheets.hasByName("Lookups"):
                raise RuntimeError("The workbook has no Lookups sheet; export it with npm run template first.")
            add_city_picker(doc, Path(os.environ["MAKE_ODS_BAS"]).read_text(encoding="utf-8"))
            doc.storeToURL(out.as_uri(), props(FilterName="calc8", Overwrite=True))
        finally:
            doc.close(True)
        result.write_text("ok")
    except Exception:
        result.write_text(traceback.format_exc())
    finally:
        desktop.terminate()


g_exportedScripts = (main,)
