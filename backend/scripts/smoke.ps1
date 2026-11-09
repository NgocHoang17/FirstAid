param([string]$BaseUrl = 'http://127.0.0.1:18080/api/v1')

$uri = [Uri]$BaseUrl
if ($uri.Host -notin @('localhost', '127.0.0.1') -or $uri.Scheme -ne 'http') {
    throw 'Smoke script only runs against a local HTTP development API.'
}
if (-not $env:TEST_ADMIN_USERNAME -or -not $env:TEST_ADMIN_PASSWORD) {
    throw 'Set TEST_ADMIN_USERNAME and TEST_ADMIN_PASSWORD in the local shell.'
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$csrf = (Invoke-RestMethod "$BaseUrl/admin/auth/csrf" -WebSession $session).data.token
$headers = @{ 'X-CSRF-TOKEN' = $csrf }
$login = @{ username = $env:TEST_ADMIN_USERNAME; password = $env:TEST_ADMIN_PASSWORD } | ConvertTo-Json -Compress
Invoke-RestMethod "$BaseUrl/admin/auth/login" -Method Post -WebSession $session -Headers $headers `
    -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($login)) | Out-Null
$headers = @{ 'X-CSRF-TOKEN' = (Invoke-RestMethod "$BaseUrl/admin/auth/csrf" -WebSession $session).data.token }

function Assert-Status([scriptblock]$Action, [int]$Expected) {
    try {
        & $Action | Out-Null
        throw "Expected HTTP $Expected, got success"
    } catch [System.Net.WebException] {
        $actual = [int]$_.Exception.Response.StatusCode
        if ($actual -ne $Expected) { throw "Expected HTTP $Expected, got $actual" }
    }
}

function Json-Bytes($Value) {
    return ,([Text.Encoding]::UTF8.GetBytes(($Value | ConvertTo-Json -Depth 12 -Compress)))
}

Assert-Status { Invoke-WebRequest "$BaseUrl/admin/articles" -UseBasicParsing } 401
$session.Headers.Remove('X-CSRF-TOKEN') | Out-Null
Assert-Status { Invoke-WebRequest "$BaseUrl/admin/categories" -Method Post -WebSession $session `
        -ContentType 'application/json' -Body '{}' -UseBasicParsing } 403
$session.Headers['X-CSRF-TOKEN'] = $headers['X-CSRF-TOKEN']

$category = (Invoke-RestMethod "$BaseUrl/categories").data.items[0].id
$source = ((Invoke-RestMethod "$BaseUrl/sources").data.items | Where-Object code -eq 'PNT2024').id
$article = @{
    category_id = $category; slug = "schema-smoke-$([Guid]::NewGuid().ToString('N'))"; variant_key = "smoke_$([Guid]::NewGuid().ToString('N'))"
    title = 'Bài thử cấu trúc, không dùng sơ cứu'; age_group = 'ADULT'; applies_to = 'Chỉ dùng trong kiểm thử local'
    summary = 'Nội dung minh họa'; recognition = @('Minh họa'); quick_actions = @('Minh họa')
    steps = @(@{ position = 1; title = 'Bước mẫu'; instruction = 'Không dùng làm hướng dẫn sơ cứu'; asset_key = $null; image_url = $null; alt_text = $null })
    warnings = @('Minh họa'); seek_help = @('Minh họa')
    references = @(
        @{ source_id = $source; page_start = 10; page_end = 10; section_key = 'all'; note = 'Ghi chú kiểm thử thứ nhất' },
        @{ source_id = $source; page_start = 10; page_end = 10; section_key = 'all'; note = 'Ghi chú kiểm thử thứ hai' }
    )
    content_checked = $false
}
try {
    $created = Invoke-RestMethod "$BaseUrl/admin/articles" -Method Post -WebSession $session -Headers $headers `
        -ContentType 'application/json' -Body (Json-Bytes $article)
} catch [System.Net.WebException] {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    throw "Create failed: $($reader.ReadToEnd())"
}
$id = $created.data.id
try {
    if ($created.data.status -ne 'DRAFT') { throw 'Article must start DRAFT' }
    if ($created.data.references.Count -ne 2) { throw 'Duplicate source/page references were lost' }
    $sourceData = (Invoke-RestMethod "$BaseUrl/admin/sources/$source" -WebSession $session).data
    $sourceData.page_count = 5
    Assert-Status { Invoke-WebRequest "$BaseUrl/admin/sources/$source" -Method Put -WebSession $session `
            -Headers $headers -ContentType 'application/json' -Body (Json-Bytes $sourceData) -UseBasicParsing } 409
    Assert-Status { Invoke-WebRequest "$BaseUrl/articles/$id" -UseBasicParsing } 404
    Assert-Status { Invoke-WebRequest "$BaseUrl/admin/articles/$id/publish" -Method Post -WebSession $session `
            -Headers $headers -ContentType 'application/json' -Body '{"expected_revision":1}' -UseBasicParsing } 422
    $article.content_checked = $true
    $article.expected_revision = 1
    $updated = Invoke-RestMethod "$BaseUrl/admin/articles/$id" -Method Put -WebSession $session -Headers $headers `
        -ContentType 'application/json' -Body (Json-Bytes $article)
    if ($updated.data.content_revision -ne 2) { throw 'Revision did not increment' }
    Assert-Status { Invoke-WebRequest "$BaseUrl/admin/articles/$id" -Method Put -WebSession $session `
            -Headers $headers -ContentType 'application/json' -Body (Json-Bytes $article) -UseBasicParsing } 409
    $before = (Invoke-WebRequest "$BaseUrl/offline-snapshot?region_code=VN-PILOT" -UseBasicParsing).Headers.ETag
    $published = Invoke-RestMethod "$BaseUrl/admin/articles/$id/publish" -Method Post -WebSession $session `
        -Headers $headers -ContentType 'application/json' -Body '{"expected_revision":2}'
    if ($published.data.status -ne 'PUBLISHED') { throw 'Publish failed' }
    $public = Invoke-RestMethod "$BaseUrl/articles/$id"
    if ($public.data.id -ne $id) { throw 'Public article missing' }
    $after = (Invoke-WebRequest "$BaseUrl/offline-snapshot?region_code=VN-PILOT" -UseBasicParsing).Headers.ETag
    if ($before -eq $after) { throw 'ETag did not change after publish' }
    Assert-Status { Invoke-WebRequest "$BaseUrl/offline-snapshot?region_code=VN-PILOT" -Headers @{ 'If-None-Match' = $after } -UseBasicParsing } 304
    $unpublished = Invoke-RestMethod "$BaseUrl/admin/articles/$id/unpublish" -Method Post -WebSession $session `
        -Headers $headers -ContentType 'application/json' -Body '{"expected_revision":2}'
    if ($unpublished.data.status -ne 'DRAFT') { throw 'Unpublish failed' }
    Assert-Status { Invoke-WebRequest "$BaseUrl/articles/$id" -UseBasicParsing } 404
    Write-Output 'PASS: auth/CSRF, duplicate references, source protection, draft/public, publish, revision, ETag/304, unpublish'
} finally {
    if ($id) { Invoke-WebRequest "$BaseUrl/admin/articles/$id" -Method Delete -WebSession $session -Headers $headers -UseBasicParsing | Out-Null }
}
