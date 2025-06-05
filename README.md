# linux-kernel-downloader
Downloader source kernel linux

## Penggunaan
```
Simple Linux Kernel Downloader

Usage: ./downloader.sh [options]

Options:
    -l, --list              Tampilkan daftar kernel tersedia
    -v, --version VERSION   Download versi kernel spesifik
    -d, --directory DIR     Set direktori download (default: current)
    -h, --help              Tampilkan bantuan ini

Examples:
    ./downloader.sh -l                   # Tampilkan daftar kernel
    ./downloader.sh -v 4.4.194          # Download kernel 4.4.194
    ./downloader.sh -v 5.15.50 -d /tmp  # Download ke /tmp

Format versi: X.Y.Z (contoh: 5.15.50, 6.1.10, 4.19.100)
```
