REM City search for LibreOffice Calc, embedded in the .ods template by scripts/make-ods.py.
REM Selecting a pg_city cell on dy_pg_info puts a search box over it: type a few letters, the list narrows,
REM pick a city (click, or Enter) and its name is written into the cell. Esc closes it without writing.
REM Only names from the Lookups sheet are written; the import still checks every value.
Option Explicit

Const SHEET_NAME = "dy_pg_info"
Const CITY_HEADER = "pg_city"
Const LOOKUP_SHEET = "Lookups"
Const BOX_NAME = "CityPicker"
Const LIST_HEIGHT = 4500 ' 1/100 mm of list shown below the cell

Global gCities As Variant
Global gReady As Boolean
Global gBusy As Boolean
Global gKeyNav As Boolean
Global gCell As Object
Global gTextL As Object
Global gItemL As Object
Global gKeyL As Object

REM Bound to the sheet's "Selection changed" event.
Sub OnSelect(oSel As Object)
	If gBusy Then Exit Sub
	If IsCityCell(oSel) Then
		ShowBox(oSel)
	Else
		HideBox()
	End If
End Sub

Function IsCityCell(oSel As Object) As Boolean
	IsCityCell = False
	If IsNull(oSel) Then Exit Function
	If Not oSel.supportsService("com.sun.star.sheet.SheetCell") Then Exit Function
	Dim a
	a = oSel.getCellAddress()
	If a.Row < 1 Then Exit Function
	Dim oSheet As Object
	oSheet = ThisComponent.Sheets.getByIndex(a.Sheet)
	If oSheet.Name <> SHEET_NAME Then Exit Function
	IsCityCell = (a.Column = CityColumn(oSheet))
End Function

Function CityColumn(oSheet As Object) As Long
	Dim c As Long, s As String
	CityColumn = -1
	For c = 0 To 1023
		s = LCase(Trim(oSheet.getCellByPosition(c, 0).getString()))
		If s = "" Then Exit Function
		If s = CITY_HEADER Then
			CityColumn = c
			Exit Function
		End If
	Next
End Function

Function BoxShape() As Object
	Dim oDP As Object, oShape As Object, i As Long
	oDP = ThisComponent.Sheets.getByName(SHEET_NAME).getDrawPage()
	For i = 0 To oDP.getCount() - 1
		oShape = oDP.getByIndex(i)
		If oShape.supportsService("com.sun.star.drawing.ControlShape") Then
			If oShape.getControl().Name = BOX_NAME Then
				BoxShape = oShape
				Exit Function
			End If
		End If
	Next
End Function

Function BoxView() As Object
	BoxView = ThisComponent.getCurrentController().getControl(BoxShape().getControl())
End Function

REM Reads the city names from the Lookups sheet and hooks the listeners up, once per open document.
Sub Init()
	If gReady Then Exit Sub
	Dim oSheet As Object, names() As String, n As Long, s As String
	oSheet = ThisComponent.Sheets.getByName(LOOKUP_SHEET)
	Do
		s = oSheet.getCellByPosition(0, n + 1).getString()
		If s = "" Then Exit Do
		ReDim Preserve names(n)
		names(n) = s
		n = n + 1
	Loop
	gCities = names
	Dim oView As Object
	oView = BoxView()
	gTextL = CreateUnoListener("Box_", "com.sun.star.awt.XTextListener")
	gItemL = CreateUnoListener("Box_", "com.sun.star.awt.XItemListener")
	gKeyL = CreateUnoListener("Box_", "com.sun.star.awt.XKeyListener")
	oView.addTextListener(gTextL)
	oView.addItemListener(gItemL)
	oView.addKeyListener(gKeyL)
	gReady = True
End Sub

REM Cities whose name starts with prefix (any case).
Function Matches(prefix As String) As Variant
	Dim out() As String, n As Long, i As Long, p As String
	p = LCase(prefix)
	For i = LBound(gCities) To UBound(gCities)
		If LCase(Left(gCities(i), Len(p))) = p Then
			ReDim Preserve out(n)
			out(n) = gCities(i)
			n = n + 1
		End If
	Next
	Matches = out
End Function

Sub SetItems(items)
	Dim oView As Object, was As Boolean
	oView = BoxView()
	was = gBusy
	gBusy = True
	oView.removeItems(0, oView.getItemCount())
	If UBound(items) >= 0 Then oView.addItems(items, 0)
	gBusy = was
End Sub

Sub SetVisible(oShape As Object, oView As Object, b As Boolean)
	Dim oModel As Object
	oModel = oShape.getControl()
	If oModel.getPropertySetInfo().hasPropertyByName("EnableVisible") Then oModel.EnableVisible = b
	oView.setVisible(b)
End Sub

Sub ShowBox(oCell As Object)
	Init()
	Dim oShape As Object, oView As Object, sz As New com.sun.star.awt.Size
	oShape = BoxShape()
	oView = BoxView()
	gCell = oCell
	oShape.setPosition(oCell.Position)
	sz.Width = oCell.Size.Width
	If sz.Width < 5000 Then sz.Width = 5000
	sz.Height = oCell.Size.Height + LIST_HEIGHT
	oShape.setSize(sz)
	gBusy = True
	oView.setText("")
	SetItems(Matches(""))
	gBusy = False
	gKeyNav = False
	SetVisible(oShape, oView, True)
	oView.setFocus()
End Sub

Sub HideBox()
	Dim oShape As Object
	oShape = BoxShape()
	If IsNull(oShape) Then Exit Sub
	SetVisible(oShape, BoxView(), False)
End Sub

REM Writes t into the cell if it is a city name (any case); otherwise writes nothing and beeps.
Function Commit(t As String) As Boolean
	Dim i As Long
	Commit = False
	If IsNull(gCell) Or IsEmpty(gCities) Then Exit Function
	For i = LBound(gCities) To UBound(gCities)
		If LCase(Trim(gCities(i))) = LCase(Trim(t)) Then
			gCell.setString(gCities(i))
			Commit = True
			Done()
			Exit Function
		End If
	Next
	Beep
End Function

REM Hide the box and give the keyboard back to the sheet.
Sub Done()
	HideBox()
	ThisComponent.getCurrentController().getFrame().getComponentWindow().setFocus()
End Sub

Sub Box_textChanged(oEv)
	If gBusy Then Exit Sub
	Dim oView As Object, t As String, sel, lo As Long
	oView = BoxView()
	t = oView.getText()
	sel = oView.getSelection()
	' AutoFill selects the letters it added; filter on what was typed
	lo = sel.Min
	If sel.Max < lo Then lo = sel.Max
	If lo < Len(t) And (sel.Min = Len(t) Or sel.Max = Len(t)) Then t = Left(t, lo)
	SetItems(Matches(t))
End Sub

Sub Box_itemStateChanged(oEv)
	If gBusy Then Exit Sub
	' Moving through the list with the arrow keys only highlights; Enter writes
	If gKeyNav Then
		gKeyNav = False
		Exit Sub
	End If
	Commit(BoxView().getItem(oEv.Selected))
End Sub

Sub Box_keyPressed(oEv)
	Select Case oEv.KeyCode
	Case 1280 ' Enter
		Commit(BoxView().getText())
	Case 1281 ' Esc
		Done()
	Case 1024, 1025 ' Down, Up
		gKeyNav = True
	End Select
End Sub

Sub Box_keyReleased(oEv)
End Sub

Sub Box_disposing(oEv)
	gReady = False
End Sub
