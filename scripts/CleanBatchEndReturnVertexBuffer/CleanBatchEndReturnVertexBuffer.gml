function CleanBatchEndReturnVertexBuffer()
{
    var _batchArray = global.__cleanBatch;
    
    if (!is_array(_batchArray))
    {
        __CleanError("Cannot end a batch, no batch started");
        exit;
    }
    
    //Don't bother doing anything if our batch is empty
	var _batchArrayLen = array_length(_batchArray);
    if (_batchArrayLen <= 0)
    {
        global.__cleanBatch = undefined;
        return undefined;
    }
    
    var _vbuff = vertex_create_buffer();
    vertex_begin(_vbuff, global.__cleanVertexFormat);
    
    var _i = 0;
    repeat(_batchArrayLen)
    {
        _batchArray[_i].__Build(_vbuff);
        ++_i;
    }
    
    vertex_end(_vbuff);
    
    global.__cleanBatch = undefined;
    
    return _vbuff;
}