Function Receive-RSJob {
    <#
        .SYNOPSIS
            Gets the results of the Windows PowerShell runspace jobs in the current session.

        .DESCRIPTION
            Gets the results of the Windows PowerShell runspace jobs in the current session. You can use
            Get-RSJob and pipe the results into this function to get the results as well.

        .PARAMETER Job
            Represents the RSJob object to receive available data from.

        .PARAMETER Name
            The name of the jobs to receive available data from.

        .PARAMETER ID
            The ID of the jobs to receive available data from.

        .PARAMETER InstanceID
            The GUID of the jobs to receive available data from.

        .PARAMETER Batch
            Name of the set of jobs to receive available data from.

        .NOTES
            Name: Receive-RSJob
            Author: Boe Prox/Max Kozlov

        .EXAMPLE
            Get-RSJob -State Completed | Receive-RSJob

            Description
            -----------
            Retrieves any available data that is outputted from completed RSJobs.

        .EXAMPLE
            Receive-RSJob -ID 1,5,78

            Description
            -----------
            Receives data from RSJob with IDs 1,5,78.

        .EXAMPLE
            Receive-RSJob -InputObject (Get-RSJob)

            Description
            -----------
            Receives data from all RSJobs.
    #>
    [cmdletbinding(
        DefaultParameterSetName='Job'
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Job', Position=0)]
        [Alias('InputObject')]
        [RSJob[]]$Job,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Name', Position=0)]
        [string[]]$Name,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Id', Position=0)]
        [int[]]$Id,
        [parameter(ValueFromPipelineByPropertyName=$True,
        ParameterSetName='InstanceID')]
        [string[]]$InstanceID,
        [parameter(ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Batch')]
        [string[]]$Batch
    )
    Begin {
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        $List = New-Object System.Collections.ArrayList
    }
    Process {
        Write-Debug "Receive-RSJob. ParameterSet: $($PSCmdlet.ParameterSetName)"
        $Property = $PSCmdlet.ParameterSetName
        # Will be good to obsolete any other parameters except Job
        if ($Property -eq 'Job') { # Receive data right from pipeline
            if ($Job) {
                [System.Threading.Monitor]::Enter($PoshRS_Jobs.syncroot)
                try {
                    $Job | TryReceiveData
                }
                finally {
                    [System.Threading.Monitor]::Exit($PoshRS_Jobs.syncroot)
                }
                $Job | WriteStream
                $Job | SetIsReceived
            }
        }
        elseif ($PSBoundParameters[$Property]) { # Receive data in the End block
            Write-Warning "Any job identification parameters considered obsolete, please, use Get-RSJob for this"
            Write-Verbose "Adding $($PSBoundParameters[$Property])"
            [void]$List.AddRange($PSBoundParameters[$Property])
        }
    }
    End {
        if ($List.Count) { # obsolete parameter sets used
            $PSBoundParameters[$Property] = $List
            Get-RSJob @PSBoundParameters | Receive-RSJob
        }
    }
}
