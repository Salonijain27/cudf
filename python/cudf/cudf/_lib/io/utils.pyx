# Copyright (c) 2020, NVIDIA CORPORATION.

from cpython.buffer cimport PyBUF_READ
from cpython.memoryview cimport PyMemoryView_FromMemory
from libcpp.memory cimport unique_ptr
from libcpp.string cimport string
from cudf._lib.cpp.io.types cimport source_info, sink_info, data_sink, io_type

import errno
import io
import os

# Converts the Python source input to libcudf++ IO source_info
# with the appropriate type and source values
cdef source_info make_source_info(src) except*:
    cdef const unsigned char[::1] buf
    if isinstance(src, bytes):
        buf = src
    elif isinstance(src, io.BytesIO):
        buf = src.getbuffer()
    # Otherwise src is expected to be a numeric fd, string path, or PathLike.
    # TODO (ptaylor): Might need to update this check if accepted input types
    #                 change when UCX and/or cuStreamz support is added.
    elif isinstance(src, (int, float, complex, basestring, os.PathLike)):
        # If source is a file, return source_info where type=FILEPATH
        if os.path.isfile(src):
            return source_info(<string> str(src).encode())
        # If source expected to be a file, raise FileNotFoundError
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), src)
    else:
        raise TypeError("Unrecognized input type: {}".format(type(src)))
    return source_info(<char*>&buf[0], buf.shape[0])


# Covnerts the Python sink input to libcudf++ IO sink_info
cdef unique_ptr[sink_info] make_sink_info(src) except*:
    cdef iobase_data_sink * bytes_sink

    if isinstance(src, io.IOBase):
        return unique_ptr[sink_info](new iobase_sink_info(src))
    elif isinstance(src, (int, float, complex, basestring, os.PathLike)):
        if os.path.isfile(src):
            return unique_ptr[sink_info](
                new sink_info(<string> str(src).encode()))
    else:
        raise TypeError("Unrecognized input type: {}".format(type(src)))


# Adapts a python io.IOBase object as a libcudf++ IO data_sink. This lets you
# write from cudf to any python file-like object (File/BytesIO/SocketIO etc)
cdef cppclass iobase_data_sink(data_sink):
    object buf

    iobase_data_sink(object buf_):
        this.buf = buf_

    void host_write(const void * data, size_t size) nogil:
        with gil:
            buf.write(PyMemoryView_FromMemory(<char*>data, size, PyBUF_READ))

    void flush() nogil:
        with gil:
            buf.flush()

    size_t bytes_written() nogil:
        with gil:
            return buf.tell()


# the sink_info class takes a raw pointer to a data_sink for user sinks.
# this creates a problem with managing the lifetime of the iobase_data_sink
# object above. This gets around by subclassing the sink_info with providing
# storage for the iobase_data_sink object
cdef cppclass iobase_sink_info(sink_info):
    unique_ptr[iobase_data_sink] sink

    iobase_sink_info(object buf):
        sink.reset(new iobase_data_sink(buf))
        this.type = io_type.USER_SINK
        this.user_sink = sink.get()
