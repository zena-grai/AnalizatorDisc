<# : batch part
@echo off
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "APP_PATH=%~f0"
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "iex ([IO.File]::ReadAllText('%~f0'))"
exit /b
: end of batch part #>

# =====================================================================
#  Анализатор диска — тёмное оконное приложение (WinForms).
#  Только смотрит и показывает. Ничего не удаляет и не меняет.
#  https://github.com/zena-grai/AnalizatorDisc
# =====================================================================

# При каждом изменении, которое заливается на GitHub, увеличивай версию:
# по ней программа понимает, что пора обновиться.
$AppVersion = '1.2.0'
$RepoUrl    = 'https://github.com/zena-grai/AnalizatorDisc'
$RawUrl     = 'https://raw.githubusercontent.com/zena-grai/AnalizatorDisc/main/DiskAnalyzer.bat'

$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public static class Native {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int attr, ref int val, int size);
    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)] static extern int SetWindowTheme(IntPtr h, string app, string id);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr h, int msg, IntPtr w, string l);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)] static extern int SetCurrentProcessExplicitAppUserModelID(string id);

    // Своё имя приложения для панели задач: иначе Windows группирует окно с PowerShell и берёт его иконку.
    public static void AppId(string id) { try { SetCurrentProcessExplicitAppUserModelID(id); } catch {} }

    public static void DarkTitleBar(IntPtr h) {
        int on = 1;
        try { if (DwmSetWindowAttribute(h, 20, ref on, 4) != 0) DwmSetWindowAttribute(h, 19, ref on, 4); } catch {}
    }
    public static void DarkScroll(IntPtr h) { try { SetWindowTheme(h, "DarkMode_Explorer", null); } catch {} }
    public static void Cue(IntPtr h, string text) { try { SendMessage(h, 0x1501, (IntPtr)1, text); } catch {} }
}

public class DarkListView : ListView {
    public DarkListView() { this.DoubleBuffered = true; }
}

public class DarkMenuColors : ProfessionalColorTable {
    static Color Bg = Color.FromArgb(43, 45, 50);
    static Color Hi = Color.FromArgb(53, 116, 240);
    static Color Ln = Color.FromArgb(60, 63, 70);
    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Ln; } }
    public override Color MenuItemBorder { get { return Hi; } }
    public override Color MenuItemSelected { get { return Hi; } }
    public override Color SeparatorDark { get { return Ln; } }
    public override Color SeparatorLight { get { return Bg; } }
}
'@
} catch {}

$script:hasNative = [bool]('Native' -as [type])
function Dark-Title($h)  { if ($script:hasNative) { [Native]::DarkTitleBar($h) } }
function Dark-Scroll($h) { if ($script:hasNative) { [Native]::DarkScroll($h) } }
function Set-Cue($h, $t) { if ($script:hasNative) { [Native]::Cue($h, $t) } }
if ($script:hasNative) { [Native]::SetProcessDPIAware() | Out-Null; [Native]::AppId('zenagrai.AnalizatorDisc') }
[System.Windows.Forms.Application]::EnableVisualStyles()

$gr0 = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
$script:k = $gr0.DpiX / 96.0
$gr0.Dispose()
function Px([double]$v) { [int][Math]::Round($v * $script:k) }

# ---------------------------------------------------------------------
#  Палитра, шрифты, иконки
# ---------------------------------------------------------------------
function Rgb([int]$r, [int]$gfx, [int]$b) { [System.Drawing.Color]::FromArgb($r, $gfx, $b) }

$C = @{
    Bg          = Rgb 30 31 34
    Side        = Rgb 37 38 43
    Rail        = Rgb 32 33 37
    Line        = Rgb 48 50 56
    Hover       = Rgb 44 46 52
    Sel         = Rgb 55 58 66
    Track       = Rgb 52 54 61
    Field       = Rgb 43 45 50
    Text        = Rgb 222 224 228
    Sub         = Rgb 150 156 166
    Dim         = Rgb 100 105 114
    Accent      = Rgb 53 116 240
    AccentHover = Rgb 82 138 246
    Green       = Rgb 80 190 120
    Orange      = Rgb 232 165 64
    Red         = Rgb 232 90 90
    RedHover    = Rgb 240 112 112
    Folder      = Rgb 226 185 92
}

$F = @{
    Ui        = New-Object System.Drawing.Font('Segoe UI', 9.5)
    UiBold    = New-Object System.Drawing.Font('Segoe UI Semibold', 9.5)
    Small     = New-Object System.Drawing.Font('Segoe UI', 8.5)
    Crumb     = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
    Title     = New-Object System.Drawing.Font('Segoe UI Semibold', 13)
    Empty     = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
    Icon      = New-Object System.Drawing.Font('Segoe MDL2 Assets', 12)
    IconSmall = New-Object System.Drawing.Font('Segoe MDL2 Assets', 10)
    IconBig   = New-Object System.Drawing.Font('Segoe MDL2 Assets', 40)
}

function Glyph([int]$code) { [string][char]$code }
$G = @{
    Folder = Glyph 0xE8B7;  File    = Glyph 0xE8A5;  Bulb   = Glyph 0xE82F
    Clean  = Glyph 0xE74D;  Info    = Glyph 0xE946;  Up     = Glyph 0xE74A
    Open   = Glyph 0xE838;  AddDir  = Glyph 0xE8F4;  Reload = Glyph 0xE72C
    Drive  = Glyph 0xEDA2;  Search  = Glyph 0xE721;  Warn   = Glyph 0xE7BA
    Ok     = Glyph 0xE73E;  Panel   = Glyph 0xE8A0;  Save = Glyph 0xE74E
    Gear   = Glyph 0xE713
}

$TF_L = [System.Windows.Forms.TextFormatFlags]'Left, VerticalCenter, EndEllipsis, NoPrefix, SingleLine'
$TF_R = [System.Windows.Forms.TextFormatFlags]'Right, VerticalCenter, EndEllipsis, NoPrefix, SingleLine'
$TF_C = [System.Windows.Forms.TextFormatFlags]'HorizontalCenter, VerticalCenter, NoPrefix, SingleLine'

# ---------------------------------------------------------------------
#  Состояние
# ---------------------------------------------------------------------
$script:results      = @{}       # путь -> результаты сканирования
$script:extraFolders = New-Object System.Collections.Generic.List[string]
$script:sel          = 'C:\'     # выбранный диск/папка
$script:view         = 'folders' # folders | files | tips
$script:scanning     = $null
$script:cancel       = $false
$script:suppress     = $false
$script:hot          = $null
$script:sideHot      = -1
$userDir = $env:USERPROFILE

# ---------------------------------------------------------------------
#  Помощники
# ---------------------------------------------------------------------
function Fmt([double]$b) {
    if     ($b -ge 1GB) { '{0:N1} ГБ' -f ($b / 1GB) }
    elseif ($b -ge 1MB) { '{0:N0} МБ' -f ($b / 1MB) }
    elseif ($b -ge 1KB) { '{0:N0} КБ' -f ($b / 1KB) }
    else                { '{0:N0} Б'  -f $b }
}

function New-Dict([string]$valueType) {
    $d = New-Object "System.Collections.Generic.Dictionary[string,$valueType]" ([StringComparer]::OrdinalIgnoreCase)
    return ,$d    # запятая не даёт PowerShell превратить пустой словарь в $null
}

function Show-Error($err) {
    [System.Windows.Forms.MessageBox]::Show(
        "Что-то пошло не так:`n`n$($err.Exception.Message)`n`nСтрока: $($err.InvocationInfo.ScriptLineNumber)",
        'Анализатор диска', 'OK', 'Error') | Out-Null
}

function Open-InExplorer([string]$path, [switch]$Select) {
    if (-not $path) { return }
    if ($Select) { Start-Process explorer.exe -ArgumentList "/select,`"$path`"" }
    else         { Start-Process explorer.exe -ArgumentList "`"$path`"" }
}

function Pt([double]$x, [double]$y) { New-Object System.Drawing.Point([int]$x, [int]$y) }
function Sz([double]$w, [double]$h) { New-Object System.Drawing.Size([int]$w, [int]$h) }
function Rect([double]$x, [double]$y, [double]$w, [double]$h) { New-Object System.Drawing.Rectangle([int]$x, [int]$y, [int]$w, [int]$h) }

function DT($gfx, [string]$text, $font, $rect, $color, $flags) {
    [System.Windows.Forms.TextRenderer]::DrawText($gfx, $text, $font, $rect, $color, [System.Windows.Forms.TextFormatFlags]$flags)
}

function Fill-Round($gfx, $color, [double]$x, [double]$y, [double]$w, [double]$h, [double]$r) {
    if ($w -lt 1 -or $h -lt 1) { return }
    $r = [Math]::Min($r, [Math]::Min($w, $h) / 2)
    $d = 2 * $r
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    if ($d -lt 1) {
        $p.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h)))
    } else {
        $p.AddArc((New-Object System.Drawing.RectangleF($x, $y, $d, $d)), 180, 90)
        $p.AddArc((New-Object System.Drawing.RectangleF(($x + $w - $d), $y, $d, $d)), 270, 90)
        $p.AddArc((New-Object System.Drawing.RectangleF(($x + $w - $d), ($y + $h - $d), $d, $d)), 0, 90)
        $p.AddArc((New-Object System.Drawing.RectangleF($x, ($y + $h - $d), $d, $d)), 90, 90)
        $p.CloseFigure()
    }
    $old = $gfx.SmoothingMode
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $br = New-Object System.Drawing.SolidBrush($color)
    $gfx.FillPath($br, $p)
    $br.Dispose(); $p.Dispose()
    $gfx.SmoothingMode = $old
}

function Level-Color([double]$freeRatio) {
    if ($freeRatio -lt 0.10) { $C.Red } elseif ($freeRatio -lt 0.20) { $C.Orange } else { $C.Green }
}

$tips = New-Object System.Windows.Forms.ToolTip

# Иконка приложения: синий скруглённый квадрат с «бубликом» заполнения диска
function New-AppIcon {
    $n = 64
    $bmp = New-Object System.Drawing.Bitmap($n, $n)
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gfx.Clear([System.Drawing.Color]::Transparent)
    Fill-Round $gfx $C.Accent 2 2 60 60 15
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $soft  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 255, 255, 255))
    $gfx.FillEllipse($soft, 12, 12, 40, 40)
    $gfx.FillPie($white, 12, 12, 40, 40, -90, 250)
    $hole = New-Object System.Drawing.SolidBrush($C.Accent)
    $gfx.FillEllipse($hole, 22, 22, 20, 20)
    $white.Dispose(); $soft.Dispose(); $hole.Dispose(); $gfx.Dispose()
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}
$AppIcon = New-AppIcon

function New-IconButton($parent, [string]$glyph, [string]$tip, [int]$size = 34) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $glyph
    $l.Font = $F.Icon
    $l.ForeColor = $C.Sub
    $l.BackColor = $parent.BackColor
    $l.TextAlign = 'MiddleCenter'
    $l.Size = Sz (Px $size) (Px $size)
    $l.Cursor = [System.Windows.Forms.Cursors]::Hand
    $l.Tag = $parent.BackColor
    $l.add_MouseEnter({ if ($this.AccessibleDescription -ne 'off') { $this.BackColor = $C.Hover; $this.ForeColor = $C.Text } })
    $l.add_MouseLeave({ $this.BackColor = $this.Tag; $this.ForeColor = if ($this.AccessibleDescription -eq 'off') { $C.Line } else { $C.Sub } })
    $tips.SetToolTip($l, $tip)
    $parent.Controls.Add($l)
    $l
}

function Set-Icon($ico, [bool]$on) {
    $ico.AccessibleDescription = if ($on) { '' } else { 'off' }
    $ico.ForeColor = if ($on) { $C.Sub } else { $C.Line }
    $ico.BackColor = $ico.Tag
    $ico.Cursor = if ($on) { [System.Windows.Forms.Cursors]::Hand } else { [System.Windows.Forms.Cursors]::Default }
}
function Icon-On($ico) { $ico.AccessibleDescription -ne 'off' }

function New-Line($parent, [string]$dock) {
    $p = New-Object System.Windows.Forms.Panel
    $p.BackColor = $C.Line
    $p.Dock = $dock
    if ($dock -eq 'Left' -or $dock -eq 'Right') { $p.Width = 1 } else { $p.Height = 1 }
    $parent.Controls.Add($p)
    $p
}

# ---------------------------------------------------------------------
#  Тёмная таблица
# ---------------------------------------------------------------------
function Draw-Cell($lv, $e) {
    $gfx = $e.Graphics; $item = $e.Item; $d = $item.Tag; $col = $e.ColumnIndex
    $b = $e.Bounds
    if ($col -eq 0) { $b = Rect $b.X $b.Y $lv.Columns[0].Width $b.Height }

    $bg = if ($item.Selected) { $C.Sel } elseif ($script:hot -eq $item) { $C.Hover } else { $C.Bg }
    $br = New-Object System.Drawing.SolidBrush($bg); $gfx.FillRectangle($br, $b); $br.Dispose()

    $pad = Px 10
    $kind = $lv.Tag[$col]
    switch ($kind) {
        'icon' {
            DT $gfx $d.Glyph $F.Icon (Rect ($b.X + $pad) $b.Y (Px 22) $b.Height) $d.GlyphColor $TF_C
            $tc = if ($d.NameColor) { $d.NameColor } else { $C.Text }
            DT $gfx $item.Text $F.Ui (Rect ($b.X + $pad + (Px 32)) $b.Y ($b.Width - $pad - (Px 36)) $b.Height) $tc $TF_L
        }
        'bar' {
            $h = Px 6
            $x = $b.X + $pad; $w = $b.Width - 2 * $pad; $y = $b.Y + ($b.Height - $h) / 2
            Fill-Round $gfx $C.Track $x $y $w $h ($h / 2)
            if ($d.Frac -gt 0) { Fill-Round $gfx $d.BarColor $x $y ([Math]::Max($w * $d.Frac, $h)) $h ($h / 2) }
        }
        default {
            $color = if ($kind -eq 'size') { $C.Text } else { $C.Sub }
            $flags = if ($lv.Columns[$col].TextAlign -eq 'Right') { $TF_R } else { $TF_L }
            DT $gfx $e.SubItem.Text $F.Ui (Rect ($b.X + $pad) $b.Y ($b.Width - 2 * $pad) $b.Height) $color $flags
        }
    }
}

function Fit-LastColumn($lv) {
    $n = $lv.Columns.Count
    if ($n -lt 2) { return }
    $used = 0
    for ($i = 0; $i -lt $n - 1; $i++) { $used += $lv.Columns[$i].Width }
    $lv.Columns[$n - 1].Width = [Math]::Max((Px 80), $lv.ClientSize.Width - $used - 2)
}

function New-DarkList([object[]]$cols) {
    $lv = if ($script:hasNative) { New-Object DarkListView } else { New-Object System.Windows.Forms.ListView }
    $lv.View = 'Details'
    $lv.FullRowSelect = $true
    $lv.HideSelection = $false
    $lv.MultiSelect = $false
    $lv.BorderStyle = 'None'
    $lv.BackColor = $C.Bg
    $lv.ForeColor = $C.Text
    $lv.Font = $F.Ui
    $lv.Dock = 'Fill'
    $lv.OwnerDraw = $true
    $lv.HeaderStyle = 'Nonclickable'
    $il = New-Object System.Windows.Forms.ImageList
    $il.ImageSize = Sz 1 (Px 36)
    $lv.SmallImageList = $il

    $kinds = @()
    foreach ($cx in $cols) {
        $h = $lv.Columns.Add($cx[0], (Px $cx[1]))
        if ($cx[2] -eq 'R') { $h.TextAlign = 'Right' }
        $kinds += $cx[3]
    }
    $lv.Tag = $kinds

    $lv.add_DrawColumnHeader({
        param($sv, $e)
        $br = New-Object System.Drawing.SolidBrush($C.Bg); $e.Graphics.FillRectangle($br, $e.Bounds); $br.Dispose()
        $br = New-Object System.Drawing.SolidBrush($C.Line)
        $e.Graphics.FillRectangle($br, $e.Bounds.X, $e.Bounds.Bottom - 1, $e.Bounds.Width, 1); $br.Dispose()
        $flags = if ($e.Header.TextAlign -eq 'Right') { $TF_R } else { $TF_L }
        $pad = Px 10
        $x = $e.Bounds.X + $pad
        if ($e.ColumnIndex -eq 0 -and $sv.Tag[0] -eq 'icon') { $x += Px 32 }
        DT $e.Graphics $e.Header.Text $F.Small (Rect $x $e.Bounds.Y ($e.Bounds.Right - $x - $pad) $e.Bounds.Height) $C.Dim $flags
    })
    $lv.add_DrawItem({ param($sv, $e) $e.DrawDefault = $false })
    $lv.add_DrawSubItem({ param($sv, $e) Draw-Cell $sv $e })
    $lv.add_MouseMove({
        $it = $this.GetItemAt($_.X, $_.Y)
        if ($it -ne $script:hot) {
            $old = $script:hot
            $script:hot = $it
            if ($old -and $old.ListView) { $old.ListView.Invalidate($old.Bounds) }
            if ($it) { $this.Invalidate($it.Bounds) }
        }
    })
    $lv.add_MouseLeave({
        $old = $script:hot; $script:hot = $null
        if ($old -and $old.ListView) { $old.ListView.Invalidate($old.Bounds) }
    })
    $lv.add_SelectedIndexChanged({ $this.Invalidate() })
    $lv.add_Resize({ Fit-LastColumn $this })
    $lv.add_HandleCreated({ Dark-Scroll $this.Handle })
    $lv
}

# ---------------------------------------------------------------------
#  Окно
# ---------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Анализатор диска'
$form.Font = $F.Ui
$form.BackColor = $C.Bg
$form.ForeColor = $C.Text
$form.Size = Sz (Px 1200) (Px 740)
$form.MinimumSize = Sz (Px 900) (Px 520)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true
if ($AppIcon) { $form.Icon = $AppIcon }
$form.add_HandleCreated({ Dark-Title $this.Handle })

# ===== Основная область (добавляется первой — занимает остаток) =====
$main = New-Object System.Windows.Forms.Panel
$main.Dock = 'Fill'
$main.BackColor = $C.Bg
$form.Controls.Add($main)

# --- Контент ---
$content = New-Object System.Windows.Forms.Panel
$content.Dock = 'Fill'
$content.BackColor = $C.Bg
$content.Padding = New-Object System.Windows.Forms.Padding((Px 8), (Px 4), (Px 8), 0)
$main.Controls.Add($content)

$lvFolders = New-DarkList @(
    @('Имя', 380, 'L', 'icon'), @('Размер', 100, 'R', 'size'), @('Доля', 240, 'L', 'bar'),
    @('%', 70, 'R', 'dim'), @('Файлов / дата', 120, 'R', 'dim'))
$lvFiles = New-DarkList @(
    @('Файл', 340, 'L', 'icon'), @('Размер', 100, 'R', 'size'), @('Изменён', 110, 'L', 'dim'),
    @('Папка', 300, 'L', 'dim'))
$lvTips = New-DarkList @(
    @('Что это', 330, 'L', 'icon'), @('Размер', 100, 'R', 'size'), @('Что с этим делать', 500, 'L', 'dim'))

$tipsPanel = New-Object System.Windows.Forms.Panel
$tipsPanel.Dock = 'Fill'; $tipsPanel.BackColor = $C.Bg
$tipsPanel.Controls.Add($lvTips)
$tipsHead = New-Object System.Windows.Forms.Panel
$tipsHead.Dock = 'Top'; $tipsHead.Height = Px 52; $tipsHead.BackColor = $C.Bg
$tipsPanel.Controls.Add($tipsHead)
$lblTipsHint = New-Object System.Windows.Forms.Label
$lblTipsHint.AutoSize = $true
$lblTipsHint.ForeColor = $C.Sub
$lblTipsHint.Text = 'Системный мусор безопаснее всего удалять через стандартную «Очистку диска» Windows.'
$lblTipsHint.Location = Pt (Px 10) (Px 17)
$tipsHead.Controls.Add($lblTipsHint)
$btnCleanmgr = New-Object System.Windows.Forms.Button
$btnCleanmgr.FlatStyle = 'Flat'
$btnCleanmgr.FlatAppearance.BorderColor = $C.Line
$btnCleanmgr.FlatAppearance.MouseOverBackColor = $C.Hover
$btnCleanmgr.BackColor = $C.Field
$btnCleanmgr.ForeColor = $C.Text
$btnCleanmgr.Text = 'Открыть «Очистку диска»'
$btnCleanmgr.Size = Sz (Px 200) (Px 32)
$btnCleanmgr.Cursor = [System.Windows.Forms.Cursors]::Hand
$tipsHead.Controls.Add($btnCleanmgr)
$tipsHead.add_Resize({ $btnCleanmgr.Location = Pt ($tipsHead.ClientSize.Width - $btnCleanmgr.Width - (Px 10)) (Px 10) })

# --- Заглушка по центру (пусто / идёт сканирование) ---
$emPanel = New-Object System.Windows.Forms.Panel
$emPanel.Dock = 'Fill'; $emPanel.BackColor = $C.Bg
$emIcon  = New-Object System.Windows.Forms.Label
$emTitle = New-Object System.Windows.Forms.Label
$emL1    = New-Object System.Windows.Forms.Label
$emL2    = New-Object System.Windows.Forms.Label
$emIcon.Font = $F.IconBig;  $emIcon.ForeColor = $C.Dim
$emTitle.Font = $F.Empty;   $emTitle.ForeColor = $C.Sub
$emL1.Font = $F.Small;      $emL1.ForeColor = $C.Dim
$emL2.Font = $F.Small;      $emL2.ForeColor = $C.Dim
foreach ($l in @($emIcon, $emTitle, $emL1, $emL2)) {
    $l.AutoSize = $true; $l.BackColor = $C.Bg; $l.TextAlign = 'MiddleCenter'
    $emPanel.Controls.Add($l)
}

function Center-Empty {
    $maxW = [Math]::Max((Px 200), $emPanel.ClientSize.Width - (Px 60))
    foreach ($l in @($emL1, $emL2)) { $l.MaximumSize = Sz $maxW 0 }
    $gap = Px 8
    $labels = @($emIcon, $emTitle, $emL1, $emL2) | Where-Object { $_.Text }
    $total = 0
    foreach ($l in $labels) { $total += $l.Height + $gap }
    $y = [int](($emPanel.ClientSize.Height - $total) / 2) - (Px 20)
    foreach ($l in @($emIcon, $emTitle, $emL1, $emL2)) {
        if (-not $l.Text) { $l.Visible = $false; continue }
        $l.Visible = $true
        $l.Location = Pt (($emPanel.ClientSize.Width - $l.Width) / 2) $y
        $y += $l.Height + $gap
    }
}
$emPanel.add_Resize({ Center-Empty })

function Set-Empty([string]$glyph, [string]$title, [string]$l1, [string]$l2) {
    $emIcon.Text = $glyph; $emTitle.Text = $title; $emL1.Text = $l1; $emL2.Text = $l2
    Center-Empty
}

$content.Controls.AddRange(@($lvFolders, $lvFiles, $tipsPanel, $emPanel))

# --- Верхняя панель ---
$topbar = New-Object System.Windows.Forms.Panel
$topbar.Dock = 'Top'; $topbar.Height = Px 60; $topbar.BackColor = $C.Bg
New-Line $topbar 'Bottom' | Out-Null
$main.Controls.Add($topbar)

$lblCrumb = New-Object System.Windows.Forms.Label
$lblCrumb.Font = $F.Crumb; $lblCrumb.ForeColor = $C.Text
$lblCrumb.AutoSize = $false; $lblCrumb.AutoEllipsis = $true
$lblCrumb.Location = Pt (Px 18) (Px 9); $lblCrumb.Height = Px 24
$lblCrumbSub = New-Object System.Windows.Forms.Label
$lblCrumbSub.Font = $F.Small; $lblCrumbSub.ForeColor = $C.Sub
$lblCrumbSub.AutoSize = $false; $lblCrumbSub.AutoEllipsis = $true
$lblCrumbSub.Location = Pt (Px 18) (Px 33); $lblCrumbSub.Height = Px 18
$topbar.Controls.AddRange(@($lblCrumb, $lblCrumbSub))

$search = New-Object System.Windows.Forms.Panel
$search.Size = Sz (Px 230) (Px 34); $search.BackColor = $C.Bg
$search.add_Paint({ Fill-Round $_.Graphics $C.Field 0 0 ($this.Width - 1) ($this.Height - 1) (Px 8) })
$searchIcon = New-Object System.Windows.Forms.Label
$searchIcon.Text = $G.Search; $searchIcon.Font = $F.IconSmall; $searchIcon.ForeColor = $C.Dim
$searchIcon.BackColor = $C.Field; $searchIcon.TextAlign = 'MiddleCenter'
$searchIcon.Size = Sz (Px 22) (Px 22); $searchIcon.Location = Pt (Px 8) (Px 6)
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.BorderStyle = 'None'; $txtSearch.BackColor = $C.Field; $txtSearch.ForeColor = $C.Text
$txtSearch.Font = $F.Ui
$txtSearch.Width = (Px 230) - (Px 44)
$txtSearch.Location = Pt (Px 34) (((Px 34) - $txtSearch.Height) / 2)
$txtSearch.add_HandleCreated({ Set-Cue $this.Handle 'Поиск  (Ctrl+F)' })
$search.Controls.AddRange(@($searchIcon, $txtSearch))
$search.add_Click({ $txtSearch.Focus() | Out-Null })
$topbar.Controls.Add($search)

$icoUp      = New-IconButton $topbar $G.Up   'Вверх  (Backspace)'
$icoExplore = New-IconButton $topbar $G.Open 'Открыть в проводнике'
$icoReport  = New-IconButton $topbar $G.Save 'Сохранить отчёт на рабочий стол  (Ctrl+S)'

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.FlatStyle = 'Flat'
$btnScan.FlatAppearance.BorderSize = 0
$btnScan.FlatAppearance.MouseOverBackColor = $C.AccentHover
$btnScan.BackColor = $C.Accent
$btnScan.ForeColor = [System.Drawing.Color]::White
$btnScan.Font = $F.UiBold
$btnScan.Text = 'Сканировать'
$btnScan.Size = Sz (Px 136) (Px 34)
$btnScan.Cursor = [System.Windows.Forms.Cursors]::Hand
$topbar.Controls.Add($btnScan)

function Layout-Topbar {
    $w = $topbar.ClientSize.Width; $h = $topbar.ClientSize.Height
    $x = $w - (Px 18) - $btnScan.Width
    $btnScan.Location = Pt $x (($h - $btnScan.Height) / 2)
    $x -= (Px 12) + $icoReport.Width
    $icoReport.Location = Pt $x (($h - $icoReport.Height) / 2)
    $x -= (Px 4) + $icoExplore.Width
    $icoExplore.Location = Pt $x (($h - $icoExplore.Height) / 2)
    $x -= (Px 4) + $icoUp.Width
    $icoUp.Location = Pt $x (($h - $icoUp.Height) / 2)
    $x -= (Px 12) + $search.Width
    $search.Location = Pt $x (($h - $search.Height) / 2)
    $cw = [Math]::Max((Px 100), $x - (Px 36))
    $lblCrumb.Width = $cw; $lblCrumbSub.Width = $cw
}
$topbar.add_Resize({ Layout-Topbar })

# --- Строка состояния ---
$statusBar = New-Object System.Windows.Forms.Panel
$statusBar.Dock = 'Bottom'; $statusBar.Height = Px 30; $statusBar.BackColor = $C.Bg
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Dock = 'Fill'; $lblStatus.AutoEllipsis = $true
$lblStatus.Font = $F.Small; $lblStatus.ForeColor = $C.Dim; $lblStatus.TextAlign = 'MiddleLeft'
$lblStatus.Padding = New-Object System.Windows.Forms.Padding((Px 16), 0, (Px 16), 0)
$lblStatus.Text = 'Программа только показывает, что занимает место. Ничего не удаляет.'
$statusBar.Controls.Add($lblStatus)
New-Line $statusBar 'Top' | Out-Null
$main.Controls.Add($statusBar)

# ===== Разделитель + боковая панель =====
$sideLine = New-Line $form 'Left'

$side = New-Object System.Windows.Forms.Panel
$side.Dock = 'Left'; $side.Width = Px 290; $side.BackColor = $C.Side
$form.Controls.Add($side)

$lb = New-Object System.Windows.Forms.ListBox
$lb.Dock = 'Fill'
$lb.BorderStyle = 'None'
$lb.BackColor = $C.Side
$lb.ForeColor = $C.Text
$lb.DrawMode = 'OwnerDrawFixed'
$lb.ItemHeight = Px 62
$lb.IntegralHeight = $false
$lb.add_HandleCreated({ Dark-Scroll $this.Handle })
$side.Controls.Add($lb)

$sideFoot = New-Object System.Windows.Forms.Panel
$sideFoot.Dock = 'Bottom'; $sideFoot.Height = Px 30; $sideFoot.BackColor = $C.Side
$lblCount = New-Object System.Windows.Forms.Label
$lblCount.Font = $F.Small; $lblCount.ForeColor = $C.Dim; $lblCount.AutoSize = $true
$lblCount.Location = Pt (Px 16) (Px 8)
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Font = $F.Small; $lblHint.ForeColor = $C.Dim; $lblHint.AutoSize = $true
$lblHint.Text = 'Ctrl+B: панель'
$sideFoot.Controls.AddRange(@($lblCount, $lblHint))
$sideFoot.add_Resize({ $lblHint.Location = Pt ($sideFoot.ClientSize.Width - $lblHint.Width - (Px 14)) (Px 8) })
New-Line $sideFoot 'Top' | Out-Null
$side.Controls.Add($sideFoot)

$sideHead = New-Object System.Windows.Forms.Panel
$sideHead.Dock = 'Top'; $sideHead.Height = Px 58; $sideHead.BackColor = $C.Side
$lblSideTitle = New-Object System.Windows.Forms.Label
$lblSideTitle.Text = 'Диски'; $lblSideTitle.Font = $F.Title; $lblSideTitle.ForeColor = $C.Text
$lblSideTitle.AutoSize = $true; $lblSideTitle.Location = Pt (Px 16) (Px 15)
$sideHead.Controls.Add($lblSideTitle)
$icoAddDir = New-IconButton $sideHead $G.AddDir 'Добавить папку для анализа' 30
$icoReload = New-IconButton $sideHead $G.Reload 'Обновить список дисков' 30
$icoAddDir.Location = Pt ((Px 290) - (Px 80)) (Px 14)
$icoReload.Location = Pt ((Px 290) - (Px 44)) (Px 14)
$side.Controls.Add($sideHead)

# ===== Разделитель + рейка с иконками (слева) =====
$railLine = New-Line $form 'Left'

$rail = New-Object System.Windows.Forms.Panel
$rail.Dock = 'Left'; $rail.Width = Px 52; $rail.BackColor = $C.Rail
$form.Controls.Add($rail)

$railBottom = New-Object System.Windows.Forms.Panel
$railBottom.Dock = 'Bottom'; $railBottom.Height = Px 148; $railBottom.BackColor = $C.Rail
$rail.Controls.Add($railBottom)

$railIndicator = New-Object System.Windows.Forms.Panel
$railIndicator.BackColor = $C.Accent
$railIndicator.Size = Sz (Px 3) (Px 22)
$rail.Controls.Add($railIndicator)

$railIcons = [ordered]@{}
$i = 0
foreach ($v in @(
        @('folders', $G.Folder, 'Папки'),
        @('files',   $G.File,   'Большие файлы'),
        @('tips',    $G.Bulb,   'Советы по очистке'))) {
    $ico = New-IconButton $rail $v[1] $v[2] 40
    $ico.Location = Pt (Px 6) ((Px 12) + $i * (Px 48))
    $ico.Name = $v[0]
    $ico.add_Click({ $script:view = $this.Name; Safe { Refresh-Main } })
    $ico.add_MouseLeave({ Update-Rail })
    $railIcons[$v[0]] = $ico
    $i++
}
$icoClean = New-IconButton $railBottom $G.Clean 'Открыть «Очистку диска» Windows' 40
$icoClean.Location = Pt (Px 6) (Px 4)
$icoInfo = New-IconButton $railBottom $G.Info 'О программе' 40
$icoInfo.Location = Pt (Px 6) (Px 52)
$icoSettings = New-IconButton $railBottom $G.Gear 'Настройки и обновления' 40
$icoSettings.Location = Pt (Px 6) (Px 100)

function Update-Rail {
    foreach ($key in $railIcons.Keys) {
        $ico = $railIcons[$key]
        if ($key -eq $script:view) {
            $ico.ForeColor = $C.Text
            $railIndicator.Location = Pt 0 ($ico.Top + ($ico.Height - $railIndicator.Height) / 2)
        } elseif ($ico.BackColor -ne $C.Hover) {
            $ico.ForeColor = $C.Sub
        }
    }
}

# --- Контекстное меню ---
$menu = New-Object System.Windows.Forms.ContextMenuStrip
try { $menu.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object DarkMenuColors)) } catch {}
$menu.BackColor = $C.Field
$miOpen = $menu.Items.Add('Открыть в проводнике')
$miCopy = $menu.Items.Add('Копировать путь')
foreach ($mi in @($miOpen, $miCopy)) { $mi.ForeColor = $C.Text }
$lvFolders.ContextMenuStrip = $menu
$lvFiles.ContextMenuStrip = $menu

# ---------------------------------------------------------------------
#  Боковая панель: диски и папки
# ---------------------------------------------------------------------
function Build-Targets {
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($d in [IO.DriveInfo]::GetDrives()) {
        if (-not $d.IsReady -or ($d.DriveType -ne 'Fixed' -and $d.DriveType -ne 'Removable')) { continue }
        $label = if ($d.VolumeLabel) { $d.VolumeLabel } else { 'Локальный диск' }
        $free = $d.TotalFreeSpace / [double]$d.TotalSize
        $list.Add([pscustomobject]@{
            Path = $d.Name; IsFolder = $false
            Title = ('{0}   {1}' -f $d.Name.TrimEnd('\'), $label)
            Sub   = ('свободно {0} из {1}' -f (Fmt $d.TotalFreeSpace), (Fmt $d.TotalSize))
            Right = (Fmt $d.TotalFreeSpace); RightColor = (Level-Color $free)
            Frac  = (1 - $free); BarColor = (Level-Color $free)
        })
    }
    foreach ($p in $script:extraFolders) {
        $name = [IO.Path]::GetFileName($p.TrimEnd('\')); if (-not $name) { $name = $p }
        $right = if ($script:results.ContainsKey($p)) { Fmt $script:results[$p].Total[$script:results[$p].Root] } else { '' }
        $list.Add([pscustomobject]@{
            Path = $p; IsFolder = $true; Title = $name; Sub = $p
            Right = $right; RightColor = $C.Sub; Frac = -1; BarColor = $C.Accent
        })
    }
    return ,$list
}

function Refresh-Sidebar {
    $script:suppress = $true
    $items = Build-Targets
    $lb.BeginUpdate()
    $lb.Items.Clear()
    foreach ($it in $items) { [void]$lb.Items.Add($it) }
    $lb.EndUpdate()
    $idx = -1
    for ($j = 0; $j -lt $items.Count; $j++) { if ($items[$j].Path -eq $script:sel) { $idx = $j; break } }
    if ($idx -lt 0 -and $items.Count) { $idx = 0; $script:sel = $items[0].Path }
    $lb.SelectedIndex = $idx
    $script:suppress = $false
    $nd = @($items | Where-Object { -not $_.IsFolder }).Count
    $nf = $items.Count - $nd
    $lblCount.Text = if ($nf) { "Дисков: $nd  ·  папок: $nf" } else { "Дисков: $nd" }
    $sideFoot.PerformLayout()
}

$lb.add_DrawItem({
    param($sv, $e)
    if ($e.Index -lt 0 -or $e.Index -ge $sv.Items.Count) { return }
    $gfx = $e.Graphics; $b = $e.Bounds; $it = $sv.Items[$e.Index]
    $br = New-Object System.Drawing.SolidBrush($C.Side); $gfx.FillRectangle($br, $b); $br.Dispose()

    $selected = ($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -ne 0
    if ($selected) { Fill-Round $gfx $C.Sel ($b.X + (Px 8)) ($b.Y + (Px 3)) ($b.Width - (Px 16)) ($b.Height - (Px 6)) (Px 6) }
    elseif ($script:sideHot -eq $e.Index) { Fill-Round $gfx $C.Hover ($b.X + (Px 8)) ($b.Y + (Px 3)) ($b.Width - (Px 16)) ($b.Height - (Px 6)) (Px 6) }

    # кружок состояния: пустой — не сканирован, зелёный — готово, синий — сканируется
    $dot = Px 8; $dx = $b.X + (Px 20); $dy = $b.Y + (Px 15)
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if ($script:scanning -eq $it.Path) {
        $br = New-Object System.Drawing.SolidBrush($C.Accent); $gfx.FillEllipse($br, $dx, $dy, $dot, $dot); $br.Dispose()
    } elseif ($script:results.ContainsKey($it.Path)) {
        $br = New-Object System.Drawing.SolidBrush($C.Green); $gfx.FillEllipse($br, $dx, $dy, $dot, $dot); $br.Dispose()
    } else {
        $pen = New-Object System.Drawing.Pen($C.Dim, [float](Px 1.5)); $gfx.DrawEllipse($pen, $dx, $dy, $dot, $dot); $pen.Dispose()
    }

    $x = $b.X + (Px 38); $rw = Px 70
    $titleFont = if ($selected) { $F.UiBold } else { $F.Ui }
    DT $gfx $it.Title $titleFont (Rect $x ($b.Y + (Px 6)) ($b.Right - $x - $rw - (Px 18)) (Px 22)) $C.Text $TF_L
    DT $gfx $it.Right $F.Small (Rect ($b.Right - $rw - (Px 18)) ($b.Y + (Px 6)) $rw (Px 22)) $it.RightColor $TF_R
    DT $gfx $it.Sub $F.Small (Rect $x ($b.Y + (Px 27)) ($b.Right - $x - (Px 18)) (Px 18)) $C.Sub $TF_L
    if ($it.Frac -ge 0) {
        $bw = $b.Right - $x - (Px 18); $bh = Px 4; $by = $b.Y + (Px 48)
        Fill-Round $gfx $C.Track $x $by $bw $bh ($bh / 2)
        Fill-Round $gfx $it.BarColor $x $by ([Math]::Max($bw * $it.Frac, $bh)) $bh ($bh / 2)
    }
})
$lb.add_MouseMove({
    $idx = $this.IndexFromPoint($_.Location)
    if ($idx -ne $script:sideHot) { $script:sideHot = $idx; $this.Invalidate() }
})
$lb.add_MouseLeave({ $script:sideHot = -1; $this.Invalidate() })

# ---------------------------------------------------------------------
#  Сканирование
# ---------------------------------------------------------------------
function Set-Busy([bool]$b) {
    if ($b) {
        $btnScan.Text = 'Остановить'
        $btnScan.BackColor = $C.Red
        $btnScan.FlatAppearance.MouseOverBackColor = $C.RedHover
    } else {
        $btnScan.Text = 'Сканировать'
        $btnScan.BackColor = $C.Accent
        $btnScan.FlatAppearance.MouseOverBackColor = $C.AccentHover
        $script:scanning = $null
    }
    Set-Icon $icoAddDir (-not $b); Set-Icon $icoReload (-not $b)
    $form.Cursor = if ($b) { [System.Windows.Forms.Cursors]::AppStarting } else { [System.Windows.Forms.Cursors]::Default }
}

function Start-Scan([string]$root) {
    if (-not $root -or -not (Test-Path -LiteralPath $root)) { return }
    $root = ([IO.DirectoryInfo]$root).FullName

    $script:scanning = $root
    $script:sel = $root
    $script:cancel = $false
    Set-Busy $true
    $lb.Invalidate()
    foreach ($cx in @($lvFolders, $lvFiles, $tipsPanel)) { $cx.Visible = $false }
    $emPanel.Visible = $true
    $lblCrumb.Text = $root
    $lblCrumbSub.Text = 'идёт сканирование…'
    Set-Icon $icoUp ($false); Set-Icon $icoExplore ($false); Set-Icon $icoReport ($false)
    Set-Empty $G.Search "Сканирую $root" 'Подготовка…' ''

    $own      = New-Dict 'long'
    $total    = New-Dict 'long'
    $files    = New-Dict 'long'
    $parentOf = New-Dict 'string'
    $children = New-Dict 'object'
    $order    = New-Object System.Collections.Generic.List[string]
    $big      = New-Object System.Collections.Generic.List[object]
    $stack    = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($root)
    $nFiles = 0L; $scanned = 0L; $denied = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()

    while ($stack.Count -gt 0) {
        $path = $stack.Pop()
        $order.Add($path)
        $sum = 0L; $cnt = 0L
        $kids = New-Object System.Collections.Generic.List[string]
        try {
            foreach ($item in ([IO.DirectoryInfo]$path).EnumerateFileSystemInfos()) {
                $attr = $item.Attributes
                if ($attr -band [IO.FileAttributes]::Directory) {
                    if ($attr -band [IO.FileAttributes]::ReparsePoint) { continue }   # ссылки не считаем дважды
                    $kids.Add($item.FullName)
                    $parentOf[$item.FullName] = $path
                    $stack.Push($item.FullName)
                }
                else {
                    if (([int]$attr -band 0x00401000) -ne 0) { continue }            # не скачанные файлы OneDrive
                    $len = $item.Length
                    $sum += $len; $cnt++
                    if ($len -ge 100MB) {
                        $big.Add([pscustomobject]@{ Path = $item.FullName; Size = $len; Date = $item.LastWriteTime })
                    }
                }
            }
        } catch { $denied++ }

        $own[$path] = $sum; $total[$path] = $sum; $files[$path] = $cnt
        $children[$path] = $kids
        $nFiles += $cnt; $scanned += $sum

        if ($order.Count % 300 -eq 0) {
            Set-Empty $G.Search "Сканирую $root" `
                ('Папок: {0:N0}   ·   файлов: {1:N0}   ·   объём: {2}   ·   {3:N0} сек' -f $order.Count, $nFiles, (Fmt $scanned), $sw.Elapsed.TotalSeconds) `
                $path
            [System.Windows.Forms.Application]::DoEvents()
            if ($script:cancel -or $form.IsDisposed) { break }
        }
    }
    if ($form.IsDisposed) { return }

    Set-Empty $G.Search "Сканирую $root" 'Подсчитываю итоги…' ''
    [System.Windows.Forms.Application]::DoEvents()
    for ($j = $order.Count - 1; $j -ge 1; $j--) {
        $p = $order[$j]; $par = $parentOf[$p]
        $total[$par] += $total[$p]
        $files[$par] += $files[$p]
    }
    $sw.Stop()

    $script:results[$root] = [pscustomobject]@{
        Root = $root; Own = $own; Total = $total; Files = $files
        ParentOf = $parentOf; Children = $children; Big = $big
        Current = $root; Scanned = $scanned; Partial = [bool]$script:cancel
    }

    $msg = 'Готово за {0:N0} сек  ·  {1:N0} файлов в {2:N0} папках  ·  всего {3}' -f $sw.Elapsed.TotalSeconds, $nFiles, $order.Count, (Fmt $scanned)
    if ($script:cancel) { $msg = 'Остановлено, результаты неполные  ·  ' + $msg }
    if ($denied -gt 0)  { $msg += "  ·  нет доступа к $denied папкам" }
    $lblStatus.Text = $msg

    Set-Busy $false
    Refresh-Sidebar
    Refresh-Main
}

# ---------------------------------------------------------------------
#  Основная область
# ---------------------------------------------------------------------
function Get-Current { if ($script:results.ContainsKey($script:sel)) { $script:results[$script:sel] } else { $null } }

function Show-Only($ctrl) {
    foreach ($cx in @($lvFolders, $lvFiles, $tipsPanel, $emPanel)) { $cx.Visible = ($cx -eq $ctrl) }
}

function Matches([string]$text) {
    $q = $txtSearch.Text.Trim()
    (-not $q) -or ($text.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function Refresh-Main {
    Update-Rail
    if ($script:scanning) { return }
    Set-Icon $icoReport ([bool](Get-Current))

    $S = Get-Current
    $item = $lb.SelectedItem
    if (-not $S) {
        Show-Only $emPanel
        $lblCrumb.Text = if ($item) { $item.Title } else { 'Анализатор диска' }
        $lblCrumbSub.Text = if ($item) { $item.Sub } else { '' }
        Set-Icon $icoUp ($false); Set-Icon $icoExplore ([bool]$item)
        Set-Empty $G.Drive 'Ещё не просканировано' `
            'Двойной клик по диску слева или кнопка «Сканировать»  ·  F5' `
            'Программа только показывает, что занимает место — ничего не удаляет'
        return
    }

    switch ($script:view) {
        'folders' { Show-Folder $S.Current }
        'files'   { Fill-BigFiles $S }
        'tips'    { Fill-Tips $S }
    }
}

function Show-Folder([string]$path) {
    $S = Get-Current
    if (-not $S) { return }
    if (-not $S.Total.ContainsKey($path)) { $path = $S.Root }
    $S.Current = $path
    $parentTotal = [double]$S.Total[$path]

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($kid in $S.Children[$path]) {
        if (-not $S.Total.ContainsKey($kid)) { continue }
        $name = [IO.Path]::GetFileName($kid)
        if (-not (Matches $name)) { continue }
        $rows.Add([pscustomobject]@{ Name = $name; Size = $S.Total[$kid]; Files = ('{0:N0}' -f $S.Files[$kid]); Path = $kid; Kind = 'dir' })
    }

    # Файлы этой папки читаем с диска прямо сейчас, чтобы показать каждый
    $fileRows = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($fi in ([IO.DirectoryInfo]$path).EnumerateFiles()) {
            if (([int]$fi.Attributes -band 0x00401000) -ne 0) { continue }   # не скачанные файлы OneDrive
            if (-not (Matches $fi.Name)) { continue }
            $fileRows.Add([pscustomobject]@{ Name = $fi.Name; Size = $fi.Length; Files = $fi.LastWriteTime.ToString('dd.MM.yyyy'); Path = $fi.FullName; Kind = 'file' })
        }
    } catch {}
    $fileRows = @($fileRows | Sort-Object Size -Descending)
    $limit = 1000
    if ($fileRows.Count -gt $limit) {
        $rest = $fileRows[$limit..($fileRows.Count - 1)]
        $restSize = ($rest | Measure-Object Size -Sum).Sum
        $rows.AddRange([object[]]$fileRows[0..($limit - 1)])
        $rows.Add([pscustomobject]@{ Name = ('…и ещё {0:N0} мелких файлов' -f $rest.Count); Size = $restSize; Files = ''; Path = $null; Kind = 'rest' })
    } elseif ($fileRows.Count) {
        $rows.AddRange([object[]]$fileRows)
    }

    $rows = @($rows | Sort-Object Size -Descending)
    $max = if ($rows.Count) { [double]$rows[0].Size } else { 0 }

    $lvFolders.BeginUpdate()
    $lvFolders.Items.Clear()
    foreach ($r in $rows) {
        $pct = if ($parentTotal -gt 0) { 100.0 * $r.Size / $parentTotal } else { 0 }
        $it = New-Object System.Windows.Forms.ListViewItem($r.Name)
        [void]$it.SubItems.Add((Fmt $r.Size))
        [void]$it.SubItems.Add('')
        [void]$it.SubItems.Add(('{0:N1}' -f $pct))
        [void]$it.SubItems.Add([string]$r.Files)
        $it.Tag = [pscustomobject]@{
            Path       = $r.Path
            File       = ($r.Kind -eq 'file')
            Glyph      = if ($r.Kind -eq 'dir') { $G.Folder } else { $G.File }
            GlyphColor = if ($r.Kind -eq 'dir') { $C.Folder } else { $C.Sub }
            NameColor  = if ($r.Kind -eq 'rest') { $C.Sub } else { $null }
            Frac       = if ($max -gt 0) { $r.Size / $max } else { 0 }
            BarColor   = if ($pct -ge 30) { $C.Red } elseif ($pct -ge 10) { $C.Orange } else { $C.Accent }
        }
        [void]$lvFolders.Items.Add($it)
    }
    $lvFolders.EndUpdate()
    Fit-LastColumn $lvFolders

    $lblCrumb.Text = $path
    $sub = '{0}  ·  {1:N0} файлов' -f (Fmt $parentTotal), $S.Files[$path]
    if ($S.Partial) { $sub += '  ·  результаты неполные' }
    $lblCrumbSub.Text = $sub
    Set-Icon $icoUp ($path -ne $S.Root)
    Set-Icon $icoExplore ($true)

    if ($rows.Count) { Show-Only $lvFolders }
    else {
        Show-Only $emPanel
        if ($txtSearch.Text.Trim()) { Set-Empty $G.Search 'Ничего не найдено' 'Попробуй изменить запрос в поиске' '' }
        else { Set-Empty $G.Folder 'Папка пуста' '' '' }
    }
}

function Fill-BigFiles($S) {
    $lvFiles.BeginUpdate()
    $lvFiles.Items.Clear()
    $n = 0
    foreach ($bf in ($S.Big | Sort-Object Size -Descending)) {
        $name = [IO.Path]::GetFileName($bf.Path)
        if (-not (Matches $bf.Path)) { continue }
        if ($n -ge 300) { break }
        $it = New-Object System.Windows.Forms.ListViewItem($name)
        [void]$it.SubItems.Add((Fmt $bf.Size))
        [void]$it.SubItems.Add($bf.Date.ToString('dd.MM.yyyy'))
        [void]$it.SubItems.Add([IO.Path]::GetDirectoryName($bf.Path))
        $it.Tag = [pscustomobject]@{ Path = $bf.Path; File = $true; Glyph = $G.File; GlyphColor = $C.Sub; NameColor = $null }
        [void]$lvFiles.Items.Add($it)
        $n++
    }
    $lvFiles.EndUpdate()
    Fit-LastColumn $lvFiles

    $lblCrumb.Text = 'Большие файлы'
    $lblCrumbSub.Text = 'от 100 МБ  ·  найдено {0}  ·  {1}' -f $S.Big.Count, $S.Root
    Set-Icon $icoUp ($false); Set-Icon $icoExplore ($false)
    if ($n) { Show-Only $lvFiles }
    else {
        Show-Only $emPanel
        if ($txtSearch.Text.Trim()) { Set-Empty $G.Search 'Ничего не найдено' 'Попробуй изменить запрос в поиске' '' }
        else { Set-Empty $G.Ok 'Больших файлов нет' 'Здесь нет ни одного файла больше 100 МБ' '' }
    }
}

$TipChecks = @(
    @('Файл гибернации (hiberfil.sys)',   'C:\hiberfil.sys', $true,  'ok',
      'Отключить: cmd от администратора → powercfg -h off. Пропадут гибернация и быстрый запуск.'),
    @('Файл подкачки (pagefile.sys)',     'C:\pagefile.sys', $true,  'info',
      'Можно уменьшить или перенести на другой диск: Свойства системы → Быстродействие → Виртуальная память.'),
    @('Старая Windows (Windows.old)',     'C:\Windows.old', $false, 'ok',
      'Очистка диска → «Очистить системные файлы» → «Предыдущие установки Windows».'),
    @('Файлы установщика ($WINDOWS.~BT)', 'C:\$WINDOWS.~BT', $false, 'ok',
      'Очистка диска → «Очистить системные файлы» → «Временные файлы установки Windows».'),
    @('Скачанные обновления Windows',     'C:\Windows\SoftwareDistribution\Download', $false, 'ok',
      'Очистка диска → «Очистить системные файлы» → «Очистка обновлений Windows».'),
    @('Хранилище компонентов (WinSxS)',   'C:\Windows\WinSxS', $false, 'warn',
      'Вручную не трогать! Сжать: Dism /Online /Cleanup-Image /StartComponentCleanup. Реальный размер меньше.'),
    @('Установщики программ (Installer)', 'C:\Windows\Installer', $false, 'warn',
      'Вручную не трогать: сломается удаление и обновление программ.'),
    @('Временные файлы Windows',          'C:\Windows\Temp', $false, 'ok', 'Можно чистить.'),
    @('Твои временные файлы',             "$userDir\AppData\Local\Temp", $false, 'ok', 'Можно чистить.'),
    @('Корзина',                          'C:\$Recycle.Bin', $false, 'ok', 'Очистить корзину.'),
    @('Папка «Загрузки»',                 "$userDir\Downloads", $false, 'info',
      'Проверь вручную: там часто лежат старые установщики и архивы.')
)

function Fill-Tips($S) {

    $lvTips.BeginUpdate()
    $lvTips.Items.Clear()
    $onC = $S.Root.StartsWith('C:\', [StringComparison]::OrdinalIgnoreCase)
    if ($onC) {
        foreach ($cx in $TipChecks) {
            if ($cx[2]) { $sv = (Get-Item -LiteralPath $cx[1] -Force).Length }
            elseif ($S.Total.ContainsKey($cx[1])) { $sv = $S.Total[$cx[1]] }
            else { $sv = 0 }
            if (-not $sv -or $sv -lt 50MB) { continue }
            if (-not (Matches ($cx[0] + ' ' + $cx[4]))) { continue }
            $it = New-Object System.Windows.Forms.ListViewItem($cx[0])
            [void]$it.SubItems.Add((Fmt $sv))
            [void]$it.SubItems.Add($cx[4])
            $glyph = switch ($cx[3]) { 'warn' { $G.Warn } 'ok' { $G.Ok } default { $G.Info } }
            $gcol  = switch ($cx[3]) { 'warn' { $C.Red } 'ok' { $C.Green } default { $C.Sub } }
            $it.Tag = [pscustomobject]@{ Path = $null; Glyph = $glyph; GlyphColor = $gcol; NameColor = $null }
            [void]$lvTips.Items.Add($it)
        }
        if ($S.Root -eq 'C:\' -and -not $S.Partial) {
            $d = New-Object IO.DriveInfo 'C'
            $hidden = ($d.TotalSize - $d.TotalFreeSpace) - $S.Scanned
            if ($hidden -gt 2GB) {
                $it = New-Object System.Windows.Forms.ListViewItem('Скрытые системные данные')
                [void]$it.SubItems.Add((Fmt $hidden))
                [void]$it.SubItems.Add('Обычно это точки восстановления. Очистка диска → «Очистить системные файлы» → «Дополнительно».')
                $it.Tag = [pscustomobject]@{ Path = $null; Glyph = $G.Info; GlyphColor = $C.Orange; NameColor = $null }
                [void]$lvTips.Items.Add($it)
            }
        }
    }
    $lvTips.EndUpdate()
    Fit-LastColumn $lvTips

    $lblCrumb.Text = 'Советы по очистке'
    $lblCrumbSub.Text = 'что занимает место на C: и можно ли это безопасно освободить'
    Set-Icon $icoUp ($false); Set-Icon $icoExplore ($false)
    if ($lvTips.Items.Count) { Show-Only $tipsPanel }
    else {
        Show-Only $emPanel
        if (-not $onC) { Set-Empty $G.Bulb 'Советы есть только для диска C:' 'Выбери слева диск C: и просканируй его' '' }
        else { Set-Empty $G.Ok 'Ничего крупного не найдено' 'Известные «пожиратели места» занимают меньше 50 МБ' '' }
    }
}

function Go-Up {
    $S = Get-Current
    if ($script:scanning -or -not $S -or $script:view -ne 'folders' -or $S.Current -eq $S.Root) { return }
    $from = $S.Current
    Show-Folder $S.ParentOf[$from]
    foreach ($it in $lvFolders.Items) {
        if ($it.Tag.Path -eq $from) { $it.Selected = $true; $it.Focused = $true; $it.EnsureVisible(); break }
    }
}

function Open-Selected {
    if ($lvFolders.SelectedItems.Count -eq 0) { return }
    $t = $lvFolders.SelectedItems[0].Tag
    if (-not $t.Path) { return }
    if ($t.File) { Open-InExplorer $t.Path -Select }
    else { $txtSearch.Text = ''; Show-Folder $t.Path }
}

# ---------------------------------------------------------------------
#  Отчёт в текстовый файл (чтобы отправить на разбор)
# ---------------------------------------------------------------------
function Add-Tree($rep, $S, [string]$path, [int]$depth, [double]$min) {
    if ($depth -ge 7 -or $rep.Count -gt 700) { return }
    $kids = @($S.Children[$path] | Where-Object { $S.Total.ContainsKey($_) -and $S.Total[$_] -ge $min } |
              Sort-Object { $S.Total[$_] } -Descending)
    $ownShown = $false
    foreach ($kid in $kids) {
        if (-not $ownShown -and $S.Own[$path] -ge $min -and $S.Own[$path] -ge $S.Total[$kid]) {
            $rep.Add(('{0,10}  {1}[файлы прямо в этой папке]' -f (Fmt $S.Own[$path]), ('    ' * $depth)))
            $ownShown = $true
        }
        $rep.Add(('{0,10}  {1}{2}' -f (Fmt $S.Total[$kid]), ('    ' * $depth), [IO.Path]::GetFileName($kid)))
        Add-Tree $rep $S $kid ($depth + 1) $min
    }
    if (-not $ownShown -and $S.Own[$path] -ge $min) {
        $rep.Add(('{0,10}  {1}[файлы прямо в этой папке]' -f (Fmt $S.Own[$path]), ('    ' * $depth)))
    }
}

function Export-Report {
    $S = Get-Current
    if (-not $S -or $script:scanning) { return }
    $root = $S.Root
    $rootTotal = [double]$S.Total[$root]
    $rep = New-Object System.Collections.Generic.List[string]
    $line = '=' * 90

    $rep.Add($line)
    $rep.Add('  ОТЧЁТ АНАЛИЗАТОРА ДИСКА')
    $rep.Add($line)
    $rep.Add(('Дата:               {0:dd.MM.yyyy HH:mm}' -f (Get-Date)))
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $rep.Add(('Система:            {0} ({1}), ОЗУ {2}' -f $os.Caption, $os.Version, (Fmt ($os.TotalVisibleMemorySize * 1KB))))
    } catch {}
    $rep.Add("Сканировалось:      $root")
    $drv = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
    if ($drv.IsReady) {
        $rep.Add(('Диск {0}             всего {1}, занято {2}, свободно {3}' -f $drv.Name.TrimEnd('\'),
            (Fmt $drv.TotalSize), (Fmt ($drv.TotalSize - $drv.TotalFreeSpace)), (Fmt $drv.TotalFreeSpace)))
    }
    $rep.Add(('Найдено файлов:     {0:N0} общим объёмом {1}' -f $S.Files[$root], (Fmt $rootTotal)))
    if ($S.Partial) { $rep.Add('ВНИМАНИЕ:           сканирование было остановлено, данные неполные') }

    $min = [Math]::Max([double]200MB, $rootTotal * 0.005)
    $rep.Add('')
    $rep.Add($line)
    $rep.Add(('  ДЕРЕВО КРУПНЫХ ПАПОК  (от {0}, вложенные папки сдвинуты вправо)' -f (Fmt $min)))
    $rep.Add($line)
    $rep.Add(('{0,10}  {1}' -f (Fmt $rootTotal), $root))
    Add-Tree $rep $S $root 1 $min

    $rep.Add('')
    $rep.Add($line)
    $rep.Add('  САМЫЕ БОЛЬШИЕ ФАЙЛЫ  (от 100 МБ, первые 50)')
    $rep.Add($line)
    $bigs = @($S.Big | Sort-Object Size -Descending | Select-Object -First 50)
    if (-not $bigs.Count) { $rep.Add('  нет') }
    foreach ($bf in $bigs) { $rep.Add(('{0,10}  {1:dd.MM.yyyy}  {2}' -f (Fmt $bf.Size), $bf.Date, $bf.Path)) }

    if ($root.StartsWith('C:\', [StringComparison]::OrdinalIgnoreCase)) {
        $rep.Add('')
        $rep.Add($line)
        $rep.Add('  ИЗВЕСТНЫЕ МЕСТА')
        $rep.Add($line)
        foreach ($cx in $TipChecks) {
            if ($cx[2]) { $sv = (Get-Item -LiteralPath $cx[1] -Force).Length }
            elseif ($S.Total.ContainsKey($cx[1])) { $sv = $S.Total[$cx[1]] }
            else { $sv = $null }
            $size = if ($sv) { Fmt $sv } else { 'нет' }
            $rep.Add(('{0,10}  {1}  [{2}]' -f $size, $cx[0], $cx[1]))
        }
        if ($root -eq 'C:\' -and -not $S.Partial -and $drv.IsReady) {
            $hidden = [double]($drv.TotalSize - $drv.TotalFreeSpace) - $rootTotal
            if ($hidden -ge 0) {
                $rep.Add(('{0,10}  Не удалось посчитать (точки восстановления, системные файлы без доступа)' -f (Fmt $hidden)))
            } else {
                $rep.Add(('{0,10}  Найдено БОЛЬШЕ, чем занято на диске: системные файлы с жёсткими ссылками (WinSxS) посчитаны дважды' -f (Fmt (-$hidden))))
            }
        }
    }

    $rep.Add('')
    $rep.Add('Отправь этот файл в чат — по нему можно разобрать, что безопасно удалить.')

    $tag = if ($root.Length -le 3) { $root.Substring(0, 1) } else { [IO.Path]::GetFileName($root.TrimEnd('\')) }
    foreach ($ch in [IO.Path]::GetInvalidFileNameChars()) { $tag = $tag.Replace([string]$ch, '_') }
    $name = 'Отчёт_диска_{0}_{1:yyyy-MM-dd_HH-mm}.txt' -f $tag, (Get-Date)
    $out = Join-Path ([Environment]::GetFolderPath('Desktop')) $name
    $rep | Set-Content -LiteralPath $out -Encoding UTF8
    $lblStatus.Text = "Отчёт сохранён на рабочий стол: $name"
    Open-InExplorer $out -Select
}

# ---------------------------------------------------------------------
#  Настройки и обновление с GitHub
# ---------------------------------------------------------------------
$SettingsFile = Join-Path $env:APPDATA 'AnalizatorDisc\settings.json'

function Load-Settings {
    $st = @{ AutoUpdate = $true }
    try {
        if (Test-Path -LiteralPath $SettingsFile) {
            $j = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $j.AutoUpdate) { $st.AutoUpdate = [bool]$j.AutoUpdate }
        }
    } catch {}
    $st
}

function Save-Settings {
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $SettingsFile) | Out-Null
        [pscustomobject]$script:settings | ConvertTo-Json | Set-Content -LiteralPath $SettingsFile -Encoding UTF8
    } catch {}
}

$script:settings  = Load-Settings
$script:update    = $null     # найденное обновление: Version, Bytes
$script:updTask   = $null
$script:updMsg    = ''
$script:updSilent = $true
$script:setUi     = $null     # элементы открытого окна настроек

$updTimer = New-Object System.Windows.Forms.Timer
$updTimer.Interval = 300

function Start-UpdateCheck([bool]$silent) {
    if ($script:updTask) { return }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {}
    $wc = New-Object System.Net.WebClient
    $wc.Headers['User-Agent'] = 'AnalizatorDisc'
    $script:updSilent = $silent
    $script:updTask = $wc.DownloadDataTaskAsync($RawUrl + '?nocache=' + [DateTime]::UtcNow.Ticks)
    $updTimer.Start()
}

function Read-RemoteVersion([byte[]]$bytes) {
    $text = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
    if (-not $text.StartsWith('<# : batch part')) { return $null }
    $m = [regex]::Match($text, "\`$AppVersion\s*=\s*'([\d.]+)'")
    if (-not $m.Success) { return $null }
    [version]$m.Groups[1].Value
}

function Set-UpdateResult([string]$msg) {
    $script:updMsg = $msg
    if ($script:update) {
        $icoSettings.ForeColor = $C.Accent
        $lblStatus.ForeColor = $C.Accent
        $lblStatus.Text = 'Доступна новая версия {0}. Открой настройки (шестерёнка слева внизу), чтобы обновиться.' -f $script:update.Version
    } elseif (-not $script:updSilent) {
        $lblStatus.ForeColor = $C.Dim
        $lblStatus.Text = $msg
    }
    if ($script:setUi) { Update-SettingsUi }
}

$updTimer.add_Tick({
    $task = $script:updTask
    if (-not $task -or -not $task.IsCompleted) { return }
    $updTimer.Stop()
    $script:updTask = $null
    if ($task.IsFaulted -or $task.IsCanceled) {
        Set-UpdateResult 'Не удалось проверить обновления: нет связи с GitHub.'
        return
    }
    $bytes  = $task.Result
    $remote = Read-RemoteVersion $bytes
    if (-not $remote) {
        Set-UpdateResult 'Файл на GitHub не похож на программу — обновление пропущено.'
        return
    }
    if ($remote -gt [version]$AppVersion) {
        $script:update = [pscustomobject]@{ Version = $remote; Bytes = $bytes }
        Set-UpdateResult ('Доступна версия {0} (у тебя {1}).' -f $remote, $AppVersion)
    } else {
        Set-UpdateResult ('У тебя последняя версия ({0}).' -f $AppVersion)
    }
})

function Apply-Update {
    $u = $script:update
    if (-not $u) { return }
    if ($script:scanning) {
        [System.Windows.Forms.MessageBox]::Show('Дождись окончания сканирования или останови его.', 'Обновление', 'OK', 'Information') | Out-Null
        return
    }
    $path = $env:APP_PATH
    if (-not $path -or -not (Test-Path -LiteralPath $path)) {
        [System.Windows.Forms.MessageBox]::Show("Не удалось найти файл программы. Скачай новую версию вручную со страницы:`n$RepoUrl", 'Обновление', 'OK', 'Warning') | Out-Null
        Start-Process $RepoUrl
        return
    }
    try {
        Copy-Item -LiteralPath $path -Destination (Join-Path $env:TEMP 'DiskAnalyzer.backup.bat') -Force
        [IO.File]::WriteAllBytes($path, $u.Bytes)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Не получилось записать файл:`n$($_.Exception.Message)", 'Обновление', 'OK', 'Error') | Out-Null
        return
    }
    Start-Process -FilePath $path
    $form.Close()
}

function Update-SettingsUi {
    $ui = $script:setUi
    if (-not $ui) { return }
    $busy = [bool]$script:updTask
    if ($script:update) {
        $ui.Status.Text = 'Доступна версия {0}. Программа скачает её с GitHub, заменит свой файл и перезапустится.' -f $script:update.Version
        $ui.Status.ForeColor = $C.Accent
        $ui.Button.Text = 'Обновить до {0}' -f $script:update.Version
    } else {
        $ui.Status.Text = if ($busy) { 'Проверяю обновления…' } elseif ($script:updMsg) { $script:updMsg } else { 'Обновления ещё не проверялись.' }
        $ui.Status.ForeColor = $C.Sub
        $ui.Button.Text = 'Проверить обновления'
    }
    $ui.Button.Enabled = -not $busy
}

function New-FlatButton([string]$text, $back, $hover, $fore) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = $hover
    $btn.BackColor = $back
    $btn.ForeColor = $fore
    $btn.Font = $F.UiBold
    $btn.Text = $text
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn
}

function Show-Settings {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = 'Настройки'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MaximizeBox = $false; $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.StartPosition = 'CenterParent'
    $dlg.BackColor = $C.Bg; $dlg.ForeColor = $C.Text; $dlg.Font = $F.Ui
    $dlg.ClientSize = Sz (Px 460) (Px 320)
    if ($AppIcon) { $dlg.Icon = $AppIcon }
    $dlg.add_HandleCreated({ Dark-Title $this.Handle })

    $logo = New-Object System.Windows.Forms.PictureBox
    $logo.Size = Sz (Px 44) (Px 44); $logo.Location = Pt (Px 24) (Px 22)
    $logo.SizeMode = 'StretchImage'
    if ($AppIcon) { $logo.Image = $AppIcon.ToBitmap() }

    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Анализатор диска'; $title.Font = $F.Title; $title.AutoSize = $true
    $title.Location = Pt (Px 80) (Px 20)

    $ver = New-Object System.Windows.Forms.Label
    $ver.Text = "Версия $AppVersion  ·  только просмотр, ничего не удаляет"
    $ver.Font = $F.Small; $ver.ForeColor = $C.Sub; $ver.AutoSize = $true
    $ver.Location = Pt (Px 82) (Px 48)

    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Text = 'github.com/zena-grai/AnalizatorDisc'
    $link.LinkColor = $C.Accent; $link.ActiveLinkColor = $C.AccentHover; $link.VisitedLinkColor = $C.Accent
    $link.LinkBehavior = 'HoverUnderline'
    $link.AutoSize = $true; $link.Location = Pt (Px 24) (Px 84)
    $link.add_LinkClicked({ Start-Process $RepoUrl })

    $sep = New-Object System.Windows.Forms.Panel
    $sep.BackColor = $C.Line; $sep.Location = Pt (Px 24) (Px 116); $sep.Size = Sz (Px 412) 1

    $sect = New-Object System.Windows.Forms.Label
    $sect.Text = 'Обновления'; $sect.Font = $F.UiBold; $sect.AutoSize = $true
    $sect.Location = Pt (Px 24) (Px 130)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = 'Проверять обновления при запуске'
    $chk.AutoSize = $true; $chk.ForeColor = $C.Text
    $chk.FlatStyle = 'Flat'
    $chk.FlatAppearance.BorderColor = $C.Sub
    $chk.FlatAppearance.CheckedBackColor = $C.Accent
    $chk.Location = Pt (Px 24) (Px 158)
    $chk.Checked = [bool]$script:settings.AutoUpdate
    $chk.add_CheckedChanged({ $script:settings.AutoUpdate = $this.Checked; Save-Settings })

    $status = New-Object System.Windows.Forms.Label
    $status.AutoSize = $false; $status.Size = Sz (Px 412) (Px 44)
    $status.Location = Pt (Px 24) (Px 192); $status.ForeColor = $C.Sub

    $btnUpd = New-FlatButton 'Проверить обновления' $C.Accent $C.AccentHover ([System.Drawing.Color]::White)
    $btnUpd.Size = Sz (Px 210) (Px 36); $btnUpd.Location = Pt (Px 24) (Px 256)
    $btnUpd.add_Click({
        if ($script:update) { Apply-Update; return }
        Start-UpdateCheck $false
        Update-SettingsUi
    })

    $btnClose = New-FlatButton 'Закрыть' $C.Field $C.Hover $C.Text
    $btnClose.Size = Sz (Px 110) (Px 36); $btnClose.Location = Pt (Px 326) (Px 256)
    $btnClose.DialogResult = 'Cancel'
    $dlg.CancelButton = $btnClose

    $dlg.Controls.AddRange(@($logo, $title, $ver, $link, $sep, $sect, $chk, $status, $btnUpd, $btnClose))
    $script:setUi = @{ Status = $status; Button = $btnUpd }
    Update-SettingsUi
    [void]$dlg.ShowDialog($form)
    $script:setUi = $null
    $dlg.Dispose()
}

function Safe([scriptblock]$block) {
    try { & $block }
    catch {
        if ($script:scanning) { Set-Busy $false }
        Show-Error $_
    }
}

# ---------------------------------------------------------------------
#  События
# ---------------------------------------------------------------------
$lb.add_SelectedIndexChanged({
    if ($script:suppress -or -not $this.SelectedItem) { return }
    if ($script:scanning) {
        $script:suppress = $true
        for ($j = 0; $j -lt $this.Items.Count; $j++) { if ($this.Items[$j].Path -eq $script:sel) { $this.SelectedIndex = $j; break } }
        $script:suppress = $false
        return
    }
    $script:sel = $this.SelectedItem.Path
    Safe { Refresh-Main }
})
$lb.add_DoubleClick({
    if ($script:scanning -or -not $this.SelectedItem) { return }
    $p = $this.SelectedItem.Path
    if (-not $script:results.ContainsKey($p)) { Safe { Start-Scan $p } }
})

$btnScan.add_Click({
    if ($script:scanning) { $script:cancel = $true; return }
    Safe { Start-Scan $script:sel }
})

$icoUp.add_Click({ if (Icon-On $this) { Safe { Go-Up } } })
$icoReport.add_Click({ if (Icon-On $this) { Safe { Export-Report } } })
$icoExplore.add_Click({
    if (-not (Icon-On $this)) { return }
    $S = Get-Current
    if ($S -and $script:view -eq 'folders') { Open-InExplorer $S.Current } else { Open-InExplorer $script:sel }
})

$icoAddDir.add_Click({
    if ($script:scanning) { return }
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Выбери папку для анализа'
    $dlg.ShowNewFolderButton = $false
    if ($dlg.ShowDialog($form) -eq 'OK') {
        $p = $dlg.SelectedPath
        if (-not $script:extraFolders.Contains($p)) { $script:extraFolders.Add($p) }
        $script:sel = $p
        Refresh-Sidebar
        Safe { Start-Scan $p }
    }
})
$icoReload.add_Click({ if (-not $script:scanning) { Refresh-Sidebar; Safe { Refresh-Main } } })

$icoClean.add_Click({ Start-Process cleanmgr.exe -ArgumentList '/d C' })
$btnCleanmgr.add_Click({ Start-Process cleanmgr.exe -ArgumentList '/d C' })
$icoSettings.add_Click({ Safe { Show-Settings } })
$icoSettings.add_MouseLeave({ if ($script:update) { $this.ForeColor = $C.Accent } })
$icoInfo.add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "Анализатор диска, версия $AppVersion`n$RepoUrl`n`nПоказывает, какие папки и файлы занимают место. Сам ничего не удаляет.`n`n" +
        "Двойной клик по диску — сканировать`nДвойной клик по папке или Enter — открыть`nBackspace — вверх`n" +
        "F5 — сканировать заново`nCtrl+S — сохранить отчёт на рабочий стол`nCtrl+F — поиск`nCtrl+B — скрыть/показать панель дисков",
        'О программе', 'OK', 'Information') | Out-Null
})

$lvFolders.add_DoubleClick({ Safe { Open-Selected } })
$lvFolders.add_KeyDown({
    if ($_.KeyCode -eq 'Enter') { Safe { Open-Selected }; $_.Handled = $true }
    if ($_.KeyCode -eq 'Back')  { Safe { Go-Up };          $_.Handled = $true }
})
$lvFiles.add_DoubleClick({
    if ($lvFiles.SelectedItems.Count) { Open-InExplorer $lvFiles.SelectedItems[0].Tag.Path -Select }
})

$menu.add_Opening({
    $lv = $menu.SourceControl
    if (-not $lv -or $lv.SelectedItems.Count -eq 0) { $_.Cancel = $true }
})
$miOpen.add_Click({
    $lv = $menu.SourceControl
    $t = $lv.SelectedItems[0].Tag
    if ($t.File) { Open-InExplorer $t.Path -Select }
    elseif ($t.Path) { Open-InExplorer $t.Path }
    else { $S = Get-Current; if ($S) { Open-InExplorer $S.Current } }
})
$miCopy.add_Click({
    $lv = $menu.SourceControl
    $p = $lv.SelectedItems[0].Tag.Path
    if (-not $p) { $S = Get-Current; if ($S) { $p = $S.Current } }
    if ($p) { [System.Windows.Forms.Clipboard]::SetText($p) }
})

$txtSearch.add_TextChanged({ if (-not $script:scanning) { Safe { Refresh-Main } } })
$txtSearch.add_KeyDown({
    if ($_.KeyCode -eq 'Escape') { $this.Text = ''; $_.SuppressKeyPress = $true }
    if ($_.KeyCode -eq 'Enter')  { $_.SuppressKeyPress = $true }
})

$form.add_KeyDown({
    if ($_.KeyCode -eq 'F5') {
        if (-not $script:scanning) { Safe { Start-Scan $script:sel } }
        $_.Handled = $true
    }
    elseif ($_.Control -and $_.KeyCode -eq 'S') { Safe { Export-Report }; $_.SuppressKeyPress = $true }
    elseif ($_.Control -and $_.KeyCode -eq 'F') { $txtSearch.Focus() | Out-Null; $txtSearch.SelectAll(); $_.SuppressKeyPress = $true }
    elseif ($_.Control -and $_.KeyCode -eq 'B') {
        $side.Visible = -not $side.Visible
        $sideLine.Visible = $side.Visible
        $_.SuppressKeyPress = $true
    }
})

$form.add_FormClosing({ $script:cancel = $true })
$form.add_Shown({
    if ($script:settings.AutoUpdate) { Start-UpdateCheck $true }
    Layout-Topbar
    Center-Empty
    $lblHint.Location = Pt ($sideFoot.ClientSize.Width - $lblHint.Width - (Px 14)) (Px 8)
    $btnCleanmgr.Location = Pt ($tipsHead.ClientSize.Width - $btnCleanmgr.Width - (Px 10)) (Px 10)
    $lb.Focus() | Out-Null
})

# ---------------------------------------------------------------------
#  Запуск
# ---------------------------------------------------------------------
Refresh-Sidebar
Refresh-Main
try {
    [System.Windows.Forms.Application]::Run($form)
} catch {
    Show-Error $_
}
