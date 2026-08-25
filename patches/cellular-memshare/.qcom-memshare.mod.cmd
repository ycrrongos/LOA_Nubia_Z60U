savedcmd_qcom-memshare.mod := printf '%s\n'   qcom_memshare.o heap_mem_ext_v01.o | awk '!x[$$0]++ { print("./"$$0) }' > qcom-memshare.mod
