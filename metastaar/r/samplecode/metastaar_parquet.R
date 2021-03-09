#!/usr/bin/env Rscript
library(Matrix)
library(arrow)

# Create a test sparse matrix:

#        0   0.0410        0   0.1220   0.2470        0
#        0        0        0        0        0        0
#        0        0        0   0.7710        0        0
#   0.3240        0        0        0   0.8310        0
#        0        0        0   0.8310        0        0
#        0        0        0        0        0        0

nrow = 6
ncol = 6
test = Matrix(nrow=nrow, ncol=ncol, data=0, sparse=T)
test[1,2] = 4
test[1,2] = 0.041
test[3,4] = 0.771
test[1,4] = 0.122
test[4,1] = 0.324
test[5,4] = 0.831
test[4,5] = 0.831
test[1,5] = 0.247

# Now we have a matrix (test) in dgCMatrix format, which is CSC (sparse column) format.
# However, parquet/arrow require equal length arrays. Triplet format (COO) works well
# for this. The `col_ind = ` line converts from the column pointer in CSC format to an
# array of column indices like what would be used in COO format.
row_ind = test@i
col_ind = as.integer(rep(1:(length(test@p) - 1), diff(test@p)) - 1)

# Example of how to convert back to a sparse matrix from COO format. 
# Each triplet of (row, column, x) defines an entry in the matrix, where x is the value.
re_sparse = sparseMatrix(i = row_ind, j = col_ind, x = test@x, index1=F)

# Specify column types for parquet. We probably only need 32-bit float for the
# covariance values.
sch = schema(
  row = int32(),
  col = int32(),
  value = float32(),
)

# Store the number of rows and columns for the sparse matrix into the
# parquet file metadata. This is needed when loading into C++ to know the
# matrix size without reading through the entire file.
sch = sch$WithMetadata(list(
  nrows = nrow, 
  ncols = ncol
))

# Create an arrow table for writing to parquet. 
tab = Table$create(
  row = row_ind,
  col = col_ind,
  value = test@x,
  schema = sch
)

# Write to parquet. Note if we specify 'chunk_size' = some number of rows, we can create
# row groups within the parquet files. This allows for running queries that only load certain
# groups, rather than the entire file.
#
# zstd compression gives a good balance between compression ratio, compression speed, and 
# decompression speed. Columns are dictionary or RLE encoded automatically first. 
write_parquet(tab, "data.parquet", compression="zstd", write_statistics=T)
