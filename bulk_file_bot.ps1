<#
    2016.12.14
    simple bot
#>

$global:ExitFlag = $false

#seconds between update request
$global:CycleLength = 3

$ChatTimeOut = 0

#bot token. Use environment variable to set up
$token = $Env:bulk_file_bot_token

#env path
$Path = Split-Path -Path ($MyInvocation.MyCommand.Path) -Parent
$logFile = "$Path\log.txt"

$chat_sessions = @{}
$currentUpdateId = 0




function log {
	param ( [parameter(Mandatory = $true)] [string]$Message )
	
        if ( (Test-Path $logFile) -and ($(Get-ChildItem $logFile).Length / 1mb) -gt 20 ) { Clear-Content $logFile }
    	$DT = Get-Date -Format "yyyy.MM.dd HH:mm:ss"
    	$MSGOut = $DT + "`t" + $Message
    	Out-File -FilePath $logFile -InputObject $MSGOut -Append -encoding unicode
}

#TODO error handling
function Bot-GetUpdates {
    param( [string]$UpdateId )

        $URL = "https://api.telegram.org/bot$token/getUpdates?offset=$UpdateId"
        $resp = Invoke-RestMethod -Uri $URL -Method Get
        return $resp.result
}

function Bot-ExtractFileId {
    param( [object[]]$Photos )
        $Photos | % {
           $w = $_."width"
           $h = $_."height"
           Write-Host "width: $w, height: $h" -ForegroundColor Green
        }
        $FileID = $Photos[-1]."file_id"
        log -Message "Extracted file_id: $FileID"
        return $FileID
}

#TODO error handling
function Bot-DownloadFile {
    param( [string]$FileID )
        
        log -Message "trying to download file_id: $FileID"

        $URL = "https://api.telegram.org/bot$token/getFile?file_id=$FileID"
        $Request = Invoke-RestMethod -Uri $URL -Method Get

        
        $Request.result | % {
            $FilePath =$_."file_path"
            Write-Host "file_path: $FilePath" -ForegroundColor Green
            $URL = "https://api.telegram.org/file/bot$token/$FilePath"
            $OutputFile = "$Path\$FilePath"
            New-Item $OutputFile -type file -force
            Invoke-WebRequest -Uri $URL -OutFile $OutputFile
        }
}

function Bot-HandleMessage {
    param( [object]$Message)
        
        $chat_id = $Message.chat.id
        Write-Host "logic start in chat: $chat_id" -ForegroundColor Green
        log -Message "logic start in chat: $chat_id"

        $text = $Message.text
        $photos = $Message.photo

        if ($photos) {
            if ($chat_sessions.ContainsKey($chat_id)) {
                $photo_id = Bot-ExtractFileId -Photo $photos
                [void]$chat_sessions.Get_Item($chat_id).Add($photo_id)
                Write-Host "Added file_id: $photo_id in session for chat $chat_id" -ForegroundColor Green
            } else {
                Write-Host "Received image without session start. Ignoring" -ForegroundColor Yellow
            }
        } else {
            if (!$text) {
                Write-Host "Unapplicable message type" -ForegroundColor Red
                log -Message "Unapplicable message type: $Message"
            } else {
                Switch ($text) {
                    '/complete_session' {
                        foreach ($FileID in $chat_sessions.Get_Item($chat_id)) {
                            Bot-DownloadFile -FileID $FileID
                        }
                        $chat_sessions.Remove($chat_id)
                        Write-Host "Finished session for chat $chat_id" -ForegroundColor Yellow
                        log -Message "Finished session for chat $chat_id"
                        break
                    }
                    '/start_session' {
                        $file_ids = [System.Collections.ArrayList]@()
                        $chat_sessions.Set_Item($chat_id, $file_ids)
                        Write-Host "Started session for chat $chat_id" -ForegroundColor Yellow
                        log -Message "Started session for chat $chat_id"
                        break   
                    }
                    default { Write-Host "Unknown command $text" -ForegroundColor Red }
                }
            }
        }
}


Write-Host 'bot start' -ForegroundColor Yellow

while ($ExitFlag -eq $False) {
    Write-Host "tick" -ForegroundColor Green

    $Msg = Bot-GetUpdates -UpdateId $currentUpdateId

    $Msg | % {
        
        $update_id = $_."update_id"
        if ($update_id -gt 1) {
            Bot-HandleMessage -Message $_."message"
            $currentUpdateId = $update_id + 1
            Write-Host "Incremented currentUpdateId: $currentUpdateId" -ForegroundColor Green
        } 
       
    }
    
    if ($ExitFlag -eq $true) {
        $Msg = Bot-GetUpdates -UpdateId $currentUpdateId
    }

    Start-Sleep -Seconds $CycleLength
}

Write-Host 'bot exit' -ForegroundColor Yellow