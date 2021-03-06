#!/bin/bash -i

echo "== START ============================================="

R_FOLDER=/usr/bin
# R_FOLDER=$HOME/progs/R/R-3.5.1/bin
# R_FOLDER=$HOME/progs/R/R-3.5.2/bin
# R_FOLDER=$HOME/progs/R/R-3.5.3/bin
# R_FOLDER=$HOME/progs/R/R-3.6.0/bin
# R_FOLDER=$HOME/progs/R/R-devel/bin

$R_FOLDER/R --version

echo "== BUILDING DOCUMENTATION ============================"
Rscript --vanilla --default-packages=methods,utils \
        -e 'devtools::document()'

echo "== REMOVING emacs lockfiles =========================="
find . -type l -exec rm {} \;

echo "== BUILDING =========================================="
# Setting this forces the testing of the autoencoders, even if there is no
# tensorflow or keras installed.
export BNET_FORCE_AUTOENCODER_TESTS=1
export BNET_FORCE_UMAP_TESTS=1
export BNET_FORCE_NNMF_TESTS=1

# this is to make the import of the nrow fail if not correctly specified
# This did not actually work, but I keep it in here for good measure.
export _R_CHECK_INSTALL_DEPENDS_=true

# if testing without all packages installed, uncomment the following line
export _R_CHECK_FORCE_SUGGESTS_=false

BNET_BUILD_VIGNETTE=1 $R_FOLDER/R CMD build --compact-vignettes .

pkgversion=$(cat DESCRIPTION | grep Version | sed 's|Version: \(.*\)|\1|')
echo "== INSTALLING version $pkgversion ===================="
$R_FOLDER/R CMD INSTALL dimRed_$pkgversion.tar.gz

echo "== LINTING ==========================================="
$R_FOLDER/Rscript -e 'lintr::lint_package()'

echo ""
echo "== CHECKING AS CRAN =================================="
$R_FOLDER/R CMD check dimRed_$pkgversion.tar.gz --as-cran --timings

echo "== CHECK everything =================================="
$R_FOLDER/R CMD check dimRed_$pkgversion.tar.gz --run-donttest --run-dontrun --timings

echo "== DONE =============================================="
