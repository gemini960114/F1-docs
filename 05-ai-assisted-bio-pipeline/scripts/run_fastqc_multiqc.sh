#!/usr/bin/env bash
# ==============================================================================
# run_fastqc_multiqc.sh - 執行 FASTQ 樣本之 FastQC 與 MultiQC 質控流程
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_DIR="${SCRIPT_DIR}/../demo_data/fastq_raw"
FASTQC_OUT="${SCRIPT_DIR}/../demo_data/fastqc_out"
MULTIQC_OUT="${SCRIPT_DIR}/../demo_data/multiqc_out"

mkdir -p "${FASTQC_OUT}" "${MULTIQC_OUT}"

echo "========================================================"
echo "🔬 [1/3] 檢查 FASTQ 原始資料與質控工具..."
echo "========================================================"

if [ ! -d "${RAW_DIR}" ] || [ -z "$(ls -A "${RAW_DIR}"/*.fastq.gz 2>/dev/null || true)" ]; then
    echo "⚠️ 尚未偵測到 FASTQ 檔案，正在呼叫 download_demo_fastq.sh 自動下載..."
    bash "${SCRIPT_DIR}/download_demo_fastq.sh"
fi

# 尋找 MultiQC (支援系統路徑、第 01 章 hpc-kernel、第 07 章 venv-proxy 或自動安裝)
MULTIQC_CMD="multiqc"
if ! command -v multiqc &>/dev/null; then
    if [ -x "${HOME}/.venv-proxy/bin/multiqc" ]; then
        MULTIQC_CMD="${HOME}/.venv-proxy/bin/multiqc"
    elif [ -x "/work1/${USER}/envs/hpc-kernel/bin/multiqc" ]; then
        MULTIQC_CMD="/work1/${USER}/envs/hpc-kernel/bin/multiqc"
    elif [ -x "${HOME}/.local/bin/multiqc" ]; then
        MULTIQC_CMD="${HOME}/.local/bin/multiqc"
    elif [ -f "/work1/${USER}/envs/hpc-kernel/bin/python" ]; then
        echo "正在透過 uv 安裝 multiqc 至第 01 章建立的 hpc-kernel 環境..."
        uv pip install --python "/work1/${USER}/envs/hpc-kernel/bin/python" multiqc
        MULTIQC_CMD="/work1/${USER}/envs/hpc-kernel/bin/multiqc"
    elif [ -f "${HOME}/.venv-proxy/bin/python" ]; then
        echo "正在透過 uv 安裝 multiqc 至第 07 章建立的 venv-proxy 環境..."
        uv pip install --python "${HOME}/.venv-proxy/bin/python" multiqc
        MULTIQC_CMD="${HOME}/.venv-proxy/bin/multiqc"
    else
        echo "正在透過 uv 建立專屬環境並安裝 multiqc..."
        uv venv "${HOME}/.venv-bio"
        uv pip install --python "${HOME}/.venv-bio/bin/python" multiqc
        MULTIQC_CMD="${HOME}/.venv-bio/bin/multiqc"
    fi
fi
echo "MultiQC 執行檔: ${MULTIQC_CMD}"

# 尋找 FastQC
FASTQC_CMD=""
if command -v fastqc &>/dev/null; then
    FASTQC_CMD="fastqc"
elif [ -x "${HOME}/bin/fastqc" ]; then
    FASTQC_CMD="${HOME}/bin/fastqc"
fi

echo "========================================================"
echo "🧬 [2/3] 執行 FastQC 品質控制分析..."
echo "========================================================"
if [ -n "${FASTQC_CMD}" ]; then
    echo "使用 FastQC: ${FASTQC_CMD}"
    "${FASTQC_CMD}" -t 4 "${RAW_DIR}"/*.fastq.gz -o "${FASTQC_OUT}"
else
    echo "ℹ️ 系統未安裝原生 Java/FastQC。為示範 MultiQC 彙整管線，"
    echo "   自動生成符合 FastQC 規範的示範質控數據檔於 ${FASTQC_OUT}..."
    for f in "${RAW_DIR}"/*.fastq.gz; do
        sample="$(basename "$f" .fastq.gz)"
        mkdir -p "/tmp/${sample}_fastqc"
        cat <<EOF > "/tmp/${sample}_fastqc/fastqc_data.txt"
##FastQC	0.12.1
>>Basic Statistics	pass
#Measure	Value
Filename	${sample}.fastq.gz
File type	Conventional base calls
Encoding	Sanger / Illumina 1.9
Total Sequences	1000
Sequences flagged as poor quality	0
Sequence length	151
%GC	51
>>END_MODULE
>>Per base sequence quality	pass
#Base	Mean	Median	Lower Quartile	Upper Quartile	10th Percentile	90th Percentile
1	32.0	33.0	30.0	35.0	28.0	36.0
2	35.0	36.0	33.0	38.0	31.0	39.0
3	36.0	37.0	34.0	39.0	32.0	40.0
>>END_MODULE
EOF
        cat <<EOF > "/tmp/${sample}_fastqc/summary.txt"
PASS	Basic Statistics	${sample}.fastq.gz
PASS	Per base sequence quality	${sample}.fastq.gz
EOF
        (cd /tmp && zip -qr "${FASTQC_OUT}/${sample}_fastqc.zip" "${sample}_fastqc")
        rm -rf "/tmp/${sample}_fastqc"
    done
fi

echo "========================================================"
echo "📊 [3/3] 執行 MultiQC 彙整產生單一 HTML 報告..."
echo "========================================================"
"${MULTIQC_CMD}" "${FASTQC_OUT}" -o "${MULTIQC_OUT}" --force

echo "--------------------------------------------------------"
echo "🎉 質控管線執行完畢！"
echo "MultiQC 報告位置: ${MULTIQC_OUT}/multiqc_report.html"
echo ""
echo "👉 預覽報告指令 (透過第 2 章 OOD 反向代理在瀏覽器直接打開):"
echo "   bash ${SCRIPT_DIR}/view_multiqc_report.sh"
echo "========================================================"
