vali_bin="$HOME/.cargo/bin/vali"
chr="22"
parquet_files_folder="/home/oliverr/nitrogenase/metastaar/sumstats"
tsv_file="/home/oliverr/nitrogenase/metastaar/sumstats/beta_p.tsv"
out_folder="/home/oliverr/nitrogenase/metastaar/sumstats/vali"
joined_files_folder="$out_folder/joined"
diff_files_folder="$out_folder/diffs"
log_files_folder="$out_folder/logs"
log_file="$log_files_folder/log$(date -Iseconds)"

function log() {
  echo "$*"
  echo "$*" >> "$log_file"
}

function exit_if_no_directory () {
    if [ ! -d "$1" ]; then
        log "Directory $1 does not exist."
        exit
    fi
}

exit_if_no_directory $parquet_files_folder
exit_if_no_directory $out_folder
exit_if_no_directory $joined_files_folder
exit_if_no_directory $diff_files_folder
exit_if_no_directory $log_files_folder

segment_max=509

for ((segment=1;segment<=segment_max;segment++)); do
    parquet_file="$parquet_files_folder/summary_statistics.chr$chr.$segment.parquet"
    if [ ! -f "$parquet_file" ]; then
        log "$parquet_file does not exist - skipping."
    elif [ ! -s "$parquet_file" ]; then
        log "$parquet_file is empty - skipping."
    else
        log "$parquet_file exists and is not empty."
        joined_file="$joined_files_folder/joined.$segment.tsv"
        parquet_only_file="$diff_files_folder/parquet_only.$segment.tsv"
        tsv_only_file="$diff_files_folder/tsv_only.$segment.tsv"
        $vali_bin parquet-tsv-p-beta-join --chr $chr --parquet-file $parquet_file --tsv-file $tsv_file \
            --joined-file $joined_file --parquet-only-file $parquet_only_file --tsv-only-file $tsv_only_file
    fi
done
