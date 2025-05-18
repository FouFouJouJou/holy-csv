#define CSV_FILE_PATH "sample.csv"

class Csv {
  U64 size;
  U8 **keys;
  StrMap **fields;
};

U64 StrSplit(U8 *content, U8 delim) {
  U64 idx = 0;
  while (content[idx] != delim && idx < StrLen(content)) {
    idx++;
  }
  return idx;
}

U64 LinesCount(U8 *content) {
  U64 counter = 0, idx = 0;
  while (idx != StrLen(content)) {
	U64 line_len = StrSplit(content+idx, '\n');
	U8 *line = StrNCpy(content+idx, line_len);
	idx += line_len+1;
	counter += 1;
	Free(line);
  }
  return counter;
}

U64 CsvColumns(U8 *column_names) {
  return StrOcc(column_names, ',') + 1;
}

U0 PopulateKeys(U8 *line, U64 len, U8 **keys) {
  U64 counter = 0, idx = 0;
  while (idx < len) {
    U64 elem_len = StrSplit(line+idx, ',');
    U8 *elem = StrNCpy(line+idx, elem_len);
    keys[counter++] = elem;
    idx+=elem_len+1;
  }
}

U0 Main() {
  U64 total_keys = 0;

  U8 *content = FileRead(CSV_FILE_PATH);
  U64 column_line_len = StrSplit(content, '\n');
  U8 *column_line = StrNCpy(content, column_line_len);

  total_keys = CsvColumns(column_line);
  U8 **keys = CAlloc(total_keys * sizeof(U8 *));
  PopulateKeys(column_line, column_line_len, keys);

  Csv csv;
  csv.keys = keys;
  csv.size = 0;

  for (U64 i=0; i<total_keys; ++i) {
    "%s, ", keys[i];
    Free(keys[i]);
  }
  Free(keys);
}