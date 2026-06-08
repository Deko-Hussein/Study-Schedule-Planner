Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$iconPath = Join-Path $root "assets\icon\icon.png"
$brandingDir = Join-Path $root "assets\branding"
$playStoreDir = Join-Path $root "play_store"
$previewDir = Join-Path $playStoreDir "previews"

New-Item -ItemType Directory -Force -Path $brandingDir | Out-Null
New-Item -ItemType Directory -Force -Path $playStoreDir | Out-Null
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

function Save-Png {
  param(
    [Parameter(Mandatory = $true)] [System.Drawing.Bitmap] $Bitmap,
    [Parameter(Mandatory = $true)] [string] $Path
  )

  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-Image {
  param(
    [Parameter(Mandatory = $true)] [System.Drawing.Image] $Image,
    [Parameter(Mandatory = $true)] [int] $Width,
    [Parameter(Mandatory = $true)] [int] $Height
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.DrawImage($Image, 0, 0, $Width, $Height)
  $graphics.Dispose()
  return $bitmap
}

function New-RoundedPath {
  param(
    [Parameter(Mandatory = $true)] [float] $X,
    [Parameter(Mandatory = $true)] [float] $Y,
    [Parameter(Mandatory = $true)] [float] $Width,
    [Parameter(Mandatory = $true)] [float] $Height,
    [Parameter(Mandatory = $true)] [float] $Radius
  )

  $diameter = $Radius * 2
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundedRectangle {
  param(
    [Parameter(Mandatory = $true)] [System.Drawing.Graphics] $Graphics,
    [Parameter(Mandatory = $true)] [System.Drawing.Brush] $Brush,
    [Parameter(Mandatory = $true)] [float] $X,
    [Parameter(Mandatory = $true)] [float] $Y,
    [Parameter(Mandatory = $true)] [float] $Width,
    [Parameter(Mandatory = $true)] [float] $Height,
    [Parameter(Mandatory = $true)] [float] $Radius
  )

  $path = New-RoundedPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
  $Graphics.FillPath($Brush, $path)
  $path.Dispose()
}

function New-SplashPreview {
  param(
    [Parameter(Mandatory = $true)] [System.Drawing.Image] $Icon,
    [Parameter(Mandatory = $true)] [System.Drawing.Color] $BackgroundColor,
    [Parameter(Mandatory = $true)] [string] $OutputPath
  )

  $preview = New-Object System.Drawing.Bitmap 1290, 2796
  $graphics = [System.Drawing.Graphics]::FromImage($preview)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.Clear($BackgroundColor)

  $iconSize = 360
  $left = [int](($preview.Width - $iconSize) / 2)
  $top = [int](($preview.Height - $iconSize) / 2)
  $graphics.DrawImage($Icon, $left, $top, $iconSize, $iconSize)

  Save-Png -Bitmap $preview -Path $OutputPath
  $graphics.Dispose()
  $preview.Dispose()
}

$icon = [System.Drawing.Bitmap]::FromFile($iconPath)
$backgroundSample = $icon.GetPixel(120, 120)
$colorTolerance = 20

$foreground = New-Object System.Drawing.Bitmap $icon.Width, $icon.Height
for ($x = 0; $x -lt $icon.Width; $x++) {
  for ($y = 0; $y -lt $icon.Height; $y++) {
    $pixel = $icon.GetPixel($x, $y)

    if ($pixel.A -eq 0) {
      $foreground.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
      continue
    }

    $isBackground = (
      [Math]::Abs($pixel.R - $backgroundSample.R) -le $colorTolerance -and
      [Math]::Abs($pixel.G - $backgroundSample.G) -le $colorTolerance -and
      [Math]::Abs($pixel.B - $backgroundSample.B) -le $colorTolerance
    )

    if ($isBackground) {
      $foreground.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
    } else {
      $foreground.SetPixel($x, $y, $pixel)
    }
  }
}

$monochrome = New-Object System.Drawing.Bitmap $foreground.Width, $foreground.Height
for ($x = 0; $x -lt $foreground.Width; $x++) {
  for ($y = 0; $y -lt $foreground.Height; $y++) {
    $pixel = $foreground.GetPixel($x, $y)
    if ($pixel.A -eq 0) {
      $monochrome.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
    } else {
      $monochrome.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, 0, 0, 0))
    }
  }
}

$playStoreIcon = Resize-Image -Image $icon -Width 512 -Height 512

$splashIcon = New-Object System.Drawing.Bitmap 1152, 1152
$splashGraphics = [System.Drawing.Graphics]::FromImage($splashIcon)
$splashGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$splashGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$splashGraphics.Clear([System.Drawing.Color]::Transparent)
$splashGraphics.DrawImage($icon, 216, 216, 720, 720)
$splashGraphics.Dispose()

$featureGraphic = New-Object System.Drawing.Bitmap 1024, 500
$featureGraphics = [System.Drawing.Graphics]::FromImage($featureGraphic)
$featureGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$featureGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$rect = New-Object System.Drawing.Rectangle 0, 0, 1024, 500
$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $rect,
  [System.Drawing.Color]::FromArgb(255, 37, 99, 235),
  [System.Drawing.Color]::FromArgb(255, 15, 23, 42),
  20.0
)
$featureGraphics.FillRectangle($gradient, $rect)

$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(40, 255, 255, 255))
$featureGraphics.FillEllipse($accentBrush, 730, -80, 280, 280)
$featureGraphics.FillEllipse($accentBrush, 800, 280, 190, 190)
$featureGraphics.FillEllipse($accentBrush, 470, 320, 160, 160)

$shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 0, 0, 0))
$featureGraphics.FillEllipse($shadowBrush, 82, 142, 264, 264)
$featureGraphics.DrawImage($icon, 70, 120, 264, 264)

$titleFont = New-Object System.Drawing.Font "Segoe UI Semibold", 38
$subtitleFont = New-Object System.Drawing.Font "Segoe UI", 18
$smallFont = New-Object System.Drawing.Font "Segoe UI Semibold", 16
$whiteBrush = [System.Drawing.Brushes]::White
$softBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(225, 219, 234, 254))

$featureGraphics.DrawString("Study Planner", $titleFont, $whiteBrush, 392, 145)
$featureGraphics.DrawString("Plan lessons. Track tasks. Finish on time.", $subtitleFont, $softBrush, 394, 205)

$cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 255, 255, 255))
Fill-RoundedRectangle -Graphics $featureGraphics -Brush $cardBrush -X 392 -Y 255 -Width 258 -Height 96 -Radius 24
$featureGraphics.DrawString("SMART SCHEDULES", $smallFont, $whiteBrush, 420, 286)

Fill-RoundedRectangle -Graphics $featureGraphics -Brush $cardBrush -X 676 -Y 255 -Width 240 -Height 96 -Radius 24
$featureGraphics.DrawString("TASK REMINDERS", $smallFont, $whiteBrush, 705, 286)

$linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 2)
$featureGraphics.DrawArc($linePen, 548, 78, 300, 180, 210, 110)
$featureGraphics.DrawArc($linePen, 580, 54, 220, 140, 210, 110)

Save-Png -Bitmap $foreground -Path (Join-Path $brandingDir "launcher_foreground.png")
Save-Png -Bitmap $monochrome -Path (Join-Path $brandingDir "launcher_monochrome.png")
Save-Png -Bitmap $splashIcon -Path (Join-Path $brandingDir "splash_icon.png")
Save-Png -Bitmap $playStoreIcon -Path (Join-Path $playStoreDir "play_store_icon_512.png")
Save-Png -Bitmap $featureGraphic -Path (Join-Path $playStoreDir "feature_graphic.png")

New-SplashPreview -Icon $icon -BackgroundColor ([System.Drawing.Color]::White) -OutputPath (Join-Path $previewDir "splash_light_preview.png")
New-SplashPreview -Icon $icon -BackgroundColor ([System.Drawing.Color]::FromArgb(255, 15, 23, 42)) -OutputPath (Join-Path $previewDir "splash_dark_preview.png")

$gradient.Dispose()
$accentBrush.Dispose()
$shadowBrush.Dispose()
$titleFont.Dispose()
$subtitleFont.Dispose()
$smallFont.Dispose()
$softBrush.Dispose()
$cardBrush.Dispose()
$linePen.Dispose()
$featureGraphics.Dispose()
$featureGraphic.Dispose()
$icon.Dispose()
$foreground.Dispose()
$monochrome.Dispose()
$playStoreIcon.Dispose()
$splashIcon.Dispose()
