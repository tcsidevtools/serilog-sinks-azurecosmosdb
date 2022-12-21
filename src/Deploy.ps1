Clear-Host;
Remove-Item "./tmp" -Recurse -Force -ErrorAction SilentlyContinue | out-null
mkdir "tmp" | out-null;
Write-Host "Building Project"
[void]($Output = & dotnet build "Serilog.Sinks.AzureCosmosDB.csproj" -v q -c Release | out-null);
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error building project";
    return;
}
else {
    Write-Host "Packing Project"

    msbuild -t:pack "Serilog.Sinks.AzureCosmosDB.csproj" -interactive:false -p:OutputPath="./tmp/" -p:Configuration=Release | out-null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error packing project";
    }
}
Write-Host "Pushing Project"

Get-ChildItem "./tmp/*.nupkg" -Name |
Foreach-Object {
    Write-Host $_;
    $path = "./tmp/${_}";
    Write-Host $path;

    dotnet nuget push $path --source github --api-key $env:GITHUB_CREDS
    if ($LASTEXITCODE -ne 0) {
        Write-Host "error pushing " -NoNewLine -ForegroundColor "Red";
        Write-Host $_.Name -NoNewLine;
        return;
    }
    Write-Host "Pushed" -ForegroundColor "Green"
}

Write-Host "Push complete! Executing clean up!";
Remove-Item "./tmp" -Recurse -Force -ErrorAction SilentlyContinue | out-null
