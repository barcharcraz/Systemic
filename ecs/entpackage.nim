import entity
import tables
type TEntPack = object
  # the componetns field stores a mapping
  # between typenames and integer offsets into
  # the datablock storeing this entities
  # components
  components: TTable[string, int]
  datablock: pointer
