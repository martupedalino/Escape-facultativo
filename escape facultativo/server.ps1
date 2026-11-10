$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
} catch {
    $port = 8081
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Mision: Escape Facultativo - FAUD UNMDP" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Servidor listo en: http://localhost:$port/" -ForegroundColor Green
Write-Host "Para salir, cierra esta ventana." -ForegroundColor Gray
Write-Host ""

Start-Process "http://localhost:$port/index.html"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($urlPath)) { $urlPath = 'index.html' }
        $decodedPath = [System.Uri]::UnescapeDataString($urlPath)
        $filePath = Join-Path $PSScriptRoot $decodedPath

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = switch ($ext) {
                '.html' { 'text/html; charset=utf-8' }
                '.css'  { 'text/css; charset=utf-8' }
                '.js'   { 'application/javascript; charset=utf-8' }
                '.png'  { 'image/png' }
                '.jpg'  { 'image/jpeg' }
                '.jpeg' { 'image/jpeg' }
                '.webp' { 'image/webp' }
                '.svg'  { 'image/svg+xml' }
                '.glb'  { 'model/gltf-binary' }
                '.gltf' { 'model/gltf+json' }
                '.bin'  { 'application/octet-stream' }
                '.mp3'  { 'audio/mpeg' }
                '.wav'  { 'audio/wav' }
                default { 'application/octet-stream' }
            }
            $response.ContentType = $mime
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    } catch {
        # ignora desconexiones de cliente
    }
}
