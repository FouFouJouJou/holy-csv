#define CSV_FILE_PATH "sample.csv"
#define CSV_BACKUP_FILE_PATH "sample.csv.bck"

class Csv {
  U64 size;
  U64 total_keys;
  U8 **keys;
  StrMap *fields[1<<12];
};

/* for whatever reason, passing a csv value makes the compiler go brrrrrrr */
U8 *GetField(Csv *csv, U64 idx, U8 *key) {
  if (idx < 0 || idx > csv->size) {
    return NULL;
  }
  for (U64 i=0; i<csv->total_keys; ++i) {
    if (!StrCmp(csv->keys[i], key)) {
      return StrMapGet(csv->fields[idx], key);
    }
  }
  return NULL;
}

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

U0 PrintfCsv(Csv *csv) {
  for (U64 line = 0; line<csv->size; ++line) {
    "{\n";
    for (U64 key = 0; key<csv->total_keys; ++key) {
      "\t%s: %s", csv->keys[key], GetField(csv, line, csv->keys[key]);
      if (key+1 != csv->total_keys) {
	",";
      }
      "\n";
    }
    "}\n";
  }
}

U8 *CsvToString(Csv *csv) {
  U8 *result = StrNew("");
  for (U64 i = 0; i<csv->total_keys; ++i) {
    result = StrMerge(result, csv->keys[i]);
    if (i+1 != csv->total_keys) {
      result = StrMerge(result, ",");
    }
  }

  for (U64 line = 0; line<csv->size; ++line) {
    U8 *line_str = StrNew("");
    for (U64 key = 0; key<csv->total_keys; ++key) {
      U8 *value = GetField(csv, line, csv->keys[key]);
      if (value == NULL) {
	line_str = StrMerge(line_str, "");
      } else {
	U8 *key_value = StrPrint(NULL
				 , "%s"
				 , GetField(csv, line, csv->keys[key]));
	line_str = StrMerge(line_str, key_value);
      }
      if (key+1 != csv->total_keys) {
	line_str = StrMerge(line_str, ",");
      }
    }
    line_str = StrMerge(line_str, "\n");
    result = StrMerge(result, line_str);
    Free(line_str);
  }
  return result;
}

U0 ParseLine(U8 *line, U64 len, Csv *csv, U64 line_idx) {
  U16 field_idx = 0, idx=0;
  StrMap *map = StrMapNew(1);
  while (idx < len) {
    U64 field_len = StrSplit(line+idx, ',');
    StrMapResize(map, csv->size+1);
    if (field_len == 0) {
      StrMapSet(map, csv->keys[field_idx], NULL);
    } else {
      U8 *field = StrNCpy(line+idx, field_len);
      StrMapSet(map, csv->keys[field_idx], field);
    }
    field_idx += 1;
    idx += field_len+1;
  }
  csv->fields[line_idx] = map;
  csv->size++;
}


U0 ParseData(U8 *data, U64 len, Csv *csv) {
  U64 char_idx = 0, line_idx = 0;
  while (char_idx < len) {
    U64 line_len = StrSplit(data+char_idx, '\n');
    U8 *line = StrNCpy(data+char_idx, line_len);
    ParseLine(line, line_len, csv, line_idx++);
    char_idx += line_len+1;
  }
}

Csv *CsvNew(U8 *data) {
  Csv *csv = MAlloc(sizeof(Csv));
  U64 total_keys = 0;

  U64 column_line_len = StrSplit(data, '\n');
  U8 *column_line = StrNCpy(data, column_line_len);

  total_keys = CsvColumns(column_line);

  U8 **keys = CAlloc(total_keys * sizeof(U8 *));
  PopulateKeys(column_line, column_line_len, keys);

  csv->keys = keys;
  csv->total_keys = total_keys;
  csv->size = 0;
  ParseData(data+column_line_len+1, StrLen(data)-column_line_len-1, csv);
  return csv;
}

U8 *CsvToJson(Csv *csv) {
  U8 *result = StrNew("[\n");
  for (U64 line = 0; line<csv->size; ++line) {
    result = StrMerge(result, "\t{\n");
    for (U64 key = 0; key<csv->total_keys; ++key) {
      U8 *key_value = StrPrint(NULL
			       , "\t\t\"%s\": \"%s\""
			       , csv->keys[key]
			       , GetField(csv, line, csv->keys[key]));
      result = StrMerge(result, key_value);
      Free(key_value);
      if (key+1 != csv->total_keys) {
	result = StrMerge(result, ",");
      }
      result = StrMerge(result, "\n");
    }
    result = StrMerge(result, "\t}");
    if (line+1 != csv->size) {
      result = StrMerge(result, ",");
    }
    result = StrMerge(result, "\n");
  }
  result = StrMerge(result, "]");
  return result;
}

U0 Help() {
  "./main --json <output.json> <input.csv>";
}

U0 Main(U64 argc, U8 **argv) {
  U8 *json_option =  "--json";
  U8 *help_option =  "--help";

  if (argc == 2 && !StrNCmp(argv[1], "--help", StrLen(help_option))) {
    Help;
    Exit(0);
  }

  if (argc != 4 || StrNCmp(argv[1], json_option, StrLen(json_option))) {
    "[ERROR]: csv file path is missing\n";
    Help;
    Exit(1);
  }

  U8 *content = FileRead(argv[3]);
  Csv *csv = CsvNew(content);
  U8 *csv_string = CsvToString(csv);
  U64 csv_len = StrLen(csv_string);
  U8 *json = CsvToJson(csv);
  FileWrite(argv[2], json, StrLen(json), O_CREAT | O_RDWR);
  Free(content);
  Free(csv);

  Exit(0);
}
