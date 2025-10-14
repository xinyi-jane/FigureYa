#!/usr/bin/env Rscript
options("repos" = c(CRAN = "https://cloud.r-project.org/"))
options(BioC_mirror = "https://bioconductor.org/")

# 检查包是否已安装
is_package_installed <- function(package_name) {
  return(package_name %in% rownames(installed.packages()))
}

# 安装CRAN包
install_cran_package <- function(package_name) {
  if (!is_package_installed(package_name)) {
    cat("Installing CRAN package:", package_name, "\n")
    tryCatch({
      install.packages(package_name, dependencies = TRUE)
      cat("Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("Package already installed:", package_name, "\n")
  }
}

# 安装Bioconductor包
install_bioc_package <- function(package_name) {
  if (!is_package_installed(package_name)) {
    cat("Installing Bioconductor package:", package_name, "\n")
    tryCatch({
      if (!is_package_installed("BiocManager")) {
        install.packages("BiocManager")
      }
      BiocManager::install(package_name, update = FALSE, ask = FALSE)
      cat("Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("Package already installed:", package_name, "\n")
  }
}

# 安装GitHub包
install_github_package <- function(repo, method = "remotes") {
  package_name <- strsplit(repo, "/")[[1]][2]
  if (!is_package_installed(package_name)) {
    cat("Installing GitHub package:", repo, "\n")
    tryCatch({
      if (method == "remotes") {
        if (!is_package_installed("remotes")) {
          install.packages("remotes")
        }
        remotes::install_github(repo, dependencies = TRUE)
      } else if (method == "devtools") {
        if (!is_package_installed("devtools")) {
          install.packages("devtools")
        }
        devtools::install_github(repo, dependencies = TRUE)
      } else if (method == "pak") {
        if (!is_package_installed("pak")) {
          install.packages("pak")
        }
        pak::pak(repo)
      }
      cat("Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("Failed to install", repo, ":", e$message, "\n")
      return(FALSE)
    })
    return(TRUE)
  } else {
    cat("Package already installed:", package_name, "\n")
    return(TRUE)
  }
}

cat("Starting package installation...\n")

# 先安装基础依赖
cat("\nInstalling basic dependencies...\n")
base_deps <- c("remotes", "devtools", "survival", "glmnet")
for (pkg in base_deps) {
  install_cran_package(pkg)
}

# 安装CRAN包
cat("\nInstalling CRAN packages...\n")
cran_packages <- c("BART", "RColorBrewer", "compareC", "dplyr", "ggbreak", 
                   "ggplot2", "ggsci", "miscTools", "plsRcox", "randomForestSRC", 
                   "rlang", "superpc", "survivalsvm", "tibble", "tidyr",
                   "naivebayes", "party", "C50", "neuralnet", "Boruta", "FSelector",
                   "mlr3", "mlr3learners", "caret", "plotly", "VIM", "gbm"
)

for (pkg in cran_packages) {
  install_cran_package(pkg)
}

# 安装Bioconductor包
cat("\nInstalling Bioconductor packages...\n")
bioc_packages <- c("ComplexHeatmap", "circlize", "mixOmics", "survcomp")
for (pkg in bioc_packages) {
  install_bioc_package(pkg)
}

# 特殊处理CoxBoost
cat("\nInstalling CoxBoost...\n")
if (!is_package_installed("CoxBoost")) {
  tryCatch({
    # 方法1: 从GitHub安装最新版本
    remotes::install_github("binderh/CoxBoost")
    cat("Successfully installed CoxBoost from GitHub\n")
  }, error = function(e) {
    cat("GitHub installation failed, trying CRAN archive...\n")
    tryCatch({
      # 方法2: 从CRAN存档安装
      install.packages("https://cran.r-project.org/src/contrib/Archive/CoxBoost/CoxBoost_1.4.tar.gz", 
                       repos = NULL, type = "source")
      cat("Successfully installed CoxBoost from archive\n")
    }, error = function(e2) {
      cat("All methods failed. Trying manual download...\n")
      # 方法3: 手动下载安装
      tryCatch({
        download.file("https://cran.r-project.org/src/contrib/Archive/CoxBoost/CoxBoost_1.4.tar.gz", 
                     "CoxBoost_1.4.tar.gz")
        install.packages("CoxBoost_1.4.tar.gz", repos = NULL, type = "source")
        cat("Successfully installed CoxBoost from local file\n")
      }, error = function(e3) {
        cat("Final attempt: installing from alternative mirror\n")
        install.packages("CoxBoost", repos = "https://cloud.r-project.org")
      })
    })
  })
} else {
  cat("CoxBoost already installed\n")
}

# 安装 mlr3extralearners (需要特殊处理)
cat("\nInstalling mlr3extralearners...\n")
if (!is_package_installed("mlr3extralearners")) {
  cat("Attempting to install mlr3extralearners from GitHub...\n")
  
  # 方法1: 使用 remotes (首选)
  success <- install_github_package("mlr-org/mlr3extralearners", method = "remotes")
  
  # 方法2: 如果 remotes 失败，尝试配置 R-universe
  if (!success) {
    cat("Remotes method failed, trying R-universe configuration...\n")
    tryCatch({
      # 临时设置 R-universe 镜像
      temp_repos <- getOption("repos")
      options(repos = c(
        mlrorg = "https://mlr-org.r-universe.dev",
        CRAN = "https://cloud.r-project.org/"
      ))
      install.packages("mlr3extralearners")
      options(repos = temp_repos)  # 恢复原来的设置
      cat("Successfully installed mlr3extralearners from R-universe\n")
    }, error = function(e) {
      cat("R-universe method failed:", e$message, "\n")
      
      # 方法3: 尝试使用 pak
      cat("Trying pak package...\n")
      install_github_package("mlr-org/mlr3extralearners", method = "pak")
    })
  }
} else {
  cat("mlr3extralearners already installed\n")
}

# 验证安装
cat("\nVerifying installation...\n")
required_packages <- c("CoxBoost", "survival", "glmnet", "randomForestSRC", "plsRcox",
                       "BART", "superpc", "survivalsvm", "mlr3", "caret", "mlr3extralearners")  # 添加 mlr3extralearners
for (pkg in required_packages) {
  if (is_package_installed(pkg)) {
    cat("✓", pkg, "is installed\n")
  } else {
    cat("✗", pkg, "is NOT installed\n")
  }
}

# 测试 mlr3extralearners 是否能正常加载
cat("\nTesting mlr3extralearners loading...\n")
if (is_package_installed("mlr3extralearners")) {
  tryCatch({
    library(mlr3extralearners)
    cat("✓ mlr3extralearners loaded successfully\n")
  }, error = function(e) {
    cat("✗ Failed to load mlr3extralearners:", e$message, "\n")
  })
}

cat("\nInstallation completed!\n")
