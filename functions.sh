#! /bin/zsh
set -eu

# This files makes functions available to allow the other scripts to verify they are running 
# in a sane environment for battery life testing.

function SystemProfilerProperty()
{
  local result=$2
  local local_result=$(system_profiler $3| grep -i $1 | cut -d ":" -f 2 | awk '{$1=$1};1')
  eval $result="'$local_result'"
}

function GetPowerProperty()
{
  SystemProfilerProperty $1 $2 "SPPowerDataType"
}

function GetDisplayProperty()
{
  SystemProfilerProperty $1 $2 "SPDisplaysDataType"
}

function CompareValue()
{
  if [ "$VALUE" != "$2" ]; then
    echo $3
    exit 127
  fi
}

CheckPowerValue()
{
  # Query value, remove newlines.
  GetPowerProperty $1 VALUE
  VALUE=$(echo $VALUE|tr -d '\n')

  CompareValue $VALUE $2 $3
}

CheckDisplayValue()
{
  # Query value, remove newlines.
  GetDisplayProperty $1 VALUE
  VALUE=$(echo $VALUE|tr -d '\n')

  CompareValue $VALUE $2 $3
}

function CheckEnv()
{
  # Use command: pmset -c gpuswtich 2 to allow switching on charger.
  # Use command: pmset -b gpuswtich 0 to force intel on battery.
  CheckPowerValue "gpuswitch" "20" "GPU mode should be set to Intel Graphics only when on battery."

  # Validate power setup.
  CheckPowerValue "charging" "NoNo" "Laptop cannot be charging during test."
  CheckPowerValue "connected" "No" "Charger cannot be connected during test."

  # Validate display setup.
  CheckDisplayValue "Automatically adjust brightness" "No" "Disable automatic brightness adjustments and unplug external monitors"

  # Use caffeinate to avoid sleeping during the tests.
  if ! pgrep -x "Amphetamine" > /dev/null; then
    echo "Use Amphetamine to prevent sleep."
    exit 127
  fi
}
