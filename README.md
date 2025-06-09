# Drive Alias Fixer

This is a script for fixing the fake serial given to drives plugged in over a USB SATA/NVMe adapter automatically.

## Usage

1. git clone the repo somewhere

2. Run './main --install' to create a udev rules.d file automatically based on generic usb device serials the host has seen in its logs prior to running the script.

3. Plug in a familiar USB SATA adapter or dock that presents with detected generic serial numbers and the script will be called to create /dev/disk/by-id/ata- and nvme- symlinks for the drive so you can use them in your applications as if they were natively plugged with the corresponding driver.

## Why

I like how when I plug in a drive I can access it by its named by-id path like: `/dev/disk/by-id/ata-TheModel-TheCode_TheSerial12345` and its respective partitions with the `-part1`/`-partX` suffix.

With USB hard drive adapters and docks, the drive model, part number and serial number can be fudged by the adapter or faked entirely. I often see these sata adapters and docks use a fake serial number like ABCDEF1234567890 which is really annoying when I want to know which drive I'm talking to and which it is.

Luckily, `smartctl -a` is capable of reading out the real model, part and serial numbers of a drive. So this script reads the output of that for a given drive and automatically creates the right /dev/disk/by-id paths the drive would have if it was presented over a real SATA controller with the AHCI driver and ata- prefix.

The other week I replaced a failing drive in a full 8-bay 8-drive raidz2 zfs zpool and attached the new drive with my "Icy Box (IB-120CL-U3) HDD Docking & Clone Station" which presents itself to the host in `lsusb` as `ID 067b:2773 Prolific Technology, Inc. PL2773 SATAII bridge controller` and under /sys the device's /serial path has a generic serial `0123456789000000005` which also gets set on any hard drive you plug in.

By attaching the replacement drive over USB the failing drive in the 8-drive array was able to contribute to the load of replacing itself with the other 7 disks. Then I zpool-offline'd the new disk and swapped it with the failing one in the front bay and zpool-online'd it again after symlinking its /dev/disk/by-id/usb-XXX_YYY_0123456789000000005 path to its new real path beginniing with ata- and with the correct model, part number and serial in the name.

Now, this will be fine if i `zpool export thePool` then `zpool import -ad /dev/disk/by-id` the pool again so it can update its knowledge of these changed by-id paths.

But wouldn't it have been nice if I could have used the true ata- path of the replacement disk in the first place? This script solves that problem.

