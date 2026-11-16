param([Parameter(Mandatory=$true)][string]$QuartusBin)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $PSScriptRoot
foreach($variant in @('skip','baseline')) {
    $folder=if($variant -eq 'skip'){$PSScriptRoot}else{Join-Path $PSScriptRoot 'matched_baseline'}
    $vcd=Join-Path $PSScriptRoot ($variant+'_activity.vcd')
    if(-not (Test-Path -LiteralPath $vcd)) {
        $inputStream=[IO.File]::OpenRead($vcd+'.gz')
        $gzip=[IO.Compression.GZipStream]::new($inputStream,[IO.Compression.CompressionMode]::Decompress)
        $outputStream=[IO.File]::Create($vcd)
        try {$gzip.CopyTo($outputStream)} finally {$outputStream.Dispose();$gzip.Dispose();$inputStream.Dispose()}
    }
    Push-Location -LiteralPath $folder
    try {
        & (Join-Path $QuartusBin 'quartus_sh.exe') --flow compile skip *> reproduced_compile.txt
        if($LASTEXITCODE -ne 0){throw "Quartus compilation failed for $variant"}
        & (Join-Path $QuartusBin 'quartus_sta.exe') -t check75.tcl *> reproduced_timing75.txt
        if($LASTEXITCODE -ne 0){throw "Timing analysis failed for $variant"}
        & (Join-Path $QuartusBin 'quartus_pow.exe') skip "--input_vcd=$vcd" --set=SDC_FILE=skip75.sdc --write_settings_files=off *> reproduced_power75.txt
        if($LASTEXITCODE -ne 0){throw "Power analysis failed for $variant"}
    } finally {Pop-Location}
}
