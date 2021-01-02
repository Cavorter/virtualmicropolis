[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string[]]$Name,

    [ValidateScript( { Test-Path -Path $_ })]
    [string]$RootPath = "C:\Users\natha\OneDrive\Pictures\LEGO\Micropolis\Modules",

    [switch]$NoThumbs
)

Begin {
    $ErrorActionPreference = "Stop"

    $context = ( Get-AzStorageAccount -ResourceGroupName virtualmicropolis -Name vmicroimages ).Context
}

Process {
    foreach ( $item in $Name ) {
        Write-Verbose "Processing module $item..."

        $contentPath = Join-Path -Path $RootPath -ChildPath $item
        if ( Test-Path -Path $contentPath ) {
            Write-Verbose "Found module files at $contentPath"

            if ( -not $NoThumbs ) {
                $imageList = ( Get-ChildItem -Path $contentPath -File ).Where( { ".jpg", ".png", ".gif" -contains $_.Extension })
                Write-Verbose "Updating thumbnails for $( $imageList.Count ) images..."
                Build-Thumbnail -FilePath $imageList.FullName
            }

            $fileList = Get-ChildItem -Path "$contentPath\*.*" -File -Recurse
            Write-Verbose "Uploading $($fileList.Count) files to storage..."
            foreach ( $file in $fileList ) {
                Write-Verbose "Processing $( $file.FullName )"
                $blobName = "module" + ( $file.FullName.Replace( $RootPath , '' ).Replace('\', '/').Replace( ' ', '-' ).Replace('_', '-').Tolower() )
                Set-AzStorageBlobContent -Context $context -File $file -Container "content" -Blob $blobName -Force
            }
        }
        else {
            throw "Unable to locate $contentPath!"
        }
    }
}