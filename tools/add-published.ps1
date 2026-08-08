<#
.SYNOPSIS
    Disabled unsafe legacy command.
#>

Write-Error 'Bulk published:true is disabled. Publication must be selected per file. Use normalize-vault-frontmatter.ps1 to add safe published:false defaults.'
exit 1
