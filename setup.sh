printf "label: gpt\n,550M,U\n,,L\n" | sfdisk /dev/nvme0n1

EFI_PART=/dev/nvme0n1p1
LUKS_PART=/dev/nvme0n1p2

EFI_MNT=/boot
mkdir "$EFI_MNT"
mkfs.vfat -F 32 -n uefi "$EFI_PART"
mount "$EFI_PART" "$EFI_MNT"

STORAGE=/crypt-storage/default
mkdir -p "$(dirname $EFI_MNT$STORAGE)"

cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 nixos-enc

pvcreate /dev/mapper/nixos-enc
vgcreate partitions /dev/mapper/nixos-enc

lvcreate -L 64G -n swap partitions
lvcreate -l 100%FREE -n fsroot partitions

vgchange -ay

mkswap -L swap /dev/partitions/swap

mkfs.btrfs -L fsroot /dev/partitions/fsroot

mount /dev/partitions/fsroot /mnt

cd /mnt
btrfs subvolume create root
btrfs subvolume create home
cd ..

umount /mnt
mount -o compress=zstd,noatime,subvol=root /dev/partitions/fsroot /mnt

mkdir /mnt/home
mount -o compress=zstd,noatime,subvol=home /dev/partitions/fsroot /mnt/home

mkdir /mnt/boot
mount /boot /mnt/boot

swapon /dev/partitions/swap