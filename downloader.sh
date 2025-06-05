#!/bin/bash

# Simple Linux Kernel Downloader
# Usage: ./downloader.sh [-l] [-v version] [-d directory]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if curl or wget is available
check_tools() {
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        print_error "curl atau wget diperlukan"
        exit 1
    fi
}

# Fetch webpage content
fetch_url() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -s "$url" 2>/dev/null
    else
        wget -qO- "$url" 2>/dev/null
    fi
}

# Get kernel list for specific major version
get_kernel_versions() {
    local major="$1"
    local url="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/"
    
    print_info "Mengambil daftar kernel ${major}.x..."
    
    local content=$(fetch_url "$url")
    if [ $? -ne 0 ] || [ -z "$content" ]; then
        echo "Error: Gagal mengakses $url"
        return 1
    fi
    
    # Extract kernel versions
    echo "$content" | grep -o 'linux-[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.xz' | \
        sed 's/linux-//g; s/\.tar\.xz//g' | \
        sort -V | tail -20
}

# Show all available kernels
show_kernel_list() {
    echo "Daftar Kernel Linux Tersedia:"
    echo "============================="
    
    check_tools
    
    for major in 6 5 4 3; do
        echo -e "\n${BLUE}=== Kernel ${major}.x Series ===${NC}"
        
        local versions=$(get_kernel_versions "$major")
        
        if [ -n "$versions" ]; then
            echo "$versions" | while IFS= read -r version; do
                if [ -n "$version" ]; then
                    echo "  $version"
                fi
            done
        else
            echo "  Tidak dapat mengambil daftar kernel ${major}.x"
        fi
    done
    
    echo -e "\n${YELLOW}Catatan: Menampilkan hingga 20 versi terbaru per series${NC}"
    echo -e "${YELLOW}Untuk download: ./downloader.sh -v <versi>${NC}"
}

# Validate kernel version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Format versi tidak valid: $version"
        print_error "Gunakan format X.Y.Z (contoh: 5.15.50)"
        return 1
    fi
    return 0
}

# Download and extract kernel
download_kernel() {
    local version="$1"
    local target_dir="${2:-.}"
    
    if ! validate_version "$version"; then
        exit 1
    fi
    
    local major=$(echo "$version" | cut -d. -f1)
    local filename="linux-${version}.tar.xz"
    local url="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/${filename}"
    local filepath="${target_dir}/${filename}"
    
    # Create target directory
    mkdir -p "$target_dir"
    
    print_info "Download kernel Linux $version"
    print_info "URL: $url"
    print_info "Target: $filepath"
    
    # Download
    if command -v curl >/dev/null 2>&1; then
        print_info "Menggunakan curl untuk download..."
        if ! curl -L --progress-bar -o "$filepath" "$url"; then
            print_error "Download gagal"
            exit 1
        fi
    else
        print_info "Menggunakan wget untuk download..."
        if ! wget --progress=bar:force -O "$filepath" "$url"; then
            print_error "Download gagal"
            exit 1
        fi
    fi
    
    print_success "Download selesai: $filename"
    
    # Extract
    print_info "Mengekstrak $filename..."
    cd "$target_dir"
    
    if tar -xf "$filename"; then
        print_success "Ekstrak selesai"
        print_info "Masuk ke direktori kernel..."
        cd "linux-$version"
        print_success "Sekarang berada di: $(pwd)"
        print_info "Anda dapat mulai konfigurasi dengan: make menuconfig"
    else
        print_error "Gagal mengekstrak $filename"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
Simple Linux Kernel Downloader

Usage: $0 [options]

Options:
    -l, --list              Tampilkan daftar kernel tersedia
    -v, --version VERSION   Download versi kernel spesifik
    -d, --directory DIR     Set direktori download (default: current)
    -h, --help              Tampilkan bantuan ini

Examples:
    $0 -l                   # Tampilkan daftar kernel
    $0 -v 4.4.194          # Download kernel 4.4.194
    $0 -v 5.15.50 -d /tmp  # Download ke /tmp

Format versi: X.Y.Z (contoh: 5.15.50, 6.1.10, 4.19.100)
EOF
}

# Interactive mode
interactive_mode() {
    show_kernel_list
    echo -e "\n${YELLOW}Masukkan versi kernel (contoh: 5.15.50):${NC}"
    read -p "> " version
    
    if [ -z "$version" ]; then
        print_error "Versi tidak boleh kosong"
        exit 1
    fi
    
    echo -e "\n${YELLOW}Direktori download (Enter untuk current dir):${NC}"
    read -p "> " dir
    dir=${dir:-.}
    
    echo -e "\n${BLUE}Akan mendownload kernel $version ke $dir${NC}"
    echo -e "${YELLOW}Lanjutkan? (y/N):${NC}"
    read -p "> " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Dibatalkan"
        exit 0
    fi
    
    download_kernel "$version" "$dir"
}

# Main function
main() {
    local show_list=false
    local version=""
    local directory="."
    local interactive=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                show_list=true
                interactive=false
                shift
                ;;
            -v|--version)
                version="$2"
                interactive=false
                shift 2
                ;;
            -d|--directory)
                directory="$2"
                shift 2
                ;;
            *)
                print_error "Opsi tidak dikenal: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute based on options
    if [ "$show_list" = true ]; then
        show_kernel_list
    elif [ -n "$version" ]; then
        download_kernel "$version" "$directory"
    elif [ "$interactive" = true ]; then
        interactive_mode
    else
        show_help
    fi
}

# Run main function
main "$@"
