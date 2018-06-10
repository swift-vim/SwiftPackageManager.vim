#include <Python.h>
#include <unistd.h>

/// Bridge PyString_AsString to both runtimes
static const char *SPyString_AsString(PyObject *input) {
#if PY_MAJOR_VERSION == 3
    return (const char *)PyUnicode_AsUTF8String(input);
#else
    return PyString_AsString(input);
#endif
}

/// Bridge PyString_FromString to both runtimes
static PyObject *SPyString_FromString(const char *input) {
#if PY_MAJOR_VERSION == 3
    return PyUnicode_FromString(input);
#else
    return PyString_FromString(input);
#endif
}
void *swiftvim_call_impl(void *func, void *arg1, void *arg2);

// module=vim, method=command|exec, str = value
void *swiftvim_call(const char *module, const char *method, const char *textArg) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject *pName = SPyString_FromString(module);
    PyObject *pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        fprintf(stderr, "swiftvim error: failed to load \"%s\"\n", module);
        return NULL;
    }

    PyObject *arg = SPyString_FromString(textArg);
    if (!arg) {
        fprintf(stderr, "swiftvim error: Cannot convert argument\n");
        return NULL;
    }
    PyObject *pFunc = PyObject_GetAttrString(pModule, method);
    void *v = swiftvim_call_impl(pFunc, arg, NULL);
    Py_DECREF(pModule);
    PyGILState_Release(gstate);
    Py_XDECREF(pFunc);
    return v;
}

void *swiftvim_get_module(const char *module) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject *pName = SPyString_FromString(module);
    PyObject *pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        fprintf(stderr, "swiftvim error: failed to load \"%s\"\n", module);
        return NULL;
    }
    PyGILState_Release(gstate);
    return pModule;
}

void *swiftvim_get_attr(void *target, const char *method) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    void *v = PyObject_GetAttrString(target, method);
    PyGILState_Release(gstate);
    return v;
}

void *swiftvim_call_impl(void *pFunc, void *arg1, void *arg2) {
    void *outValue = NULL;
    // pFunc is a new reference 
    if (pFunc && PyCallable_Check(pFunc)) {
        int argCt = 0;
        if (arg1) {
            argCt++;
        }
        if (arg2) {
            argCt++;
        }

        PyObject *pArgs = PyTuple_New(argCt);
        /// Add args if needed
        if (arg1) {
            PyTuple_SetItem(pArgs, 0, arg1);
        }
        if (arg2) {
            PyTuple_SetItem(pArgs, 1, arg2);
        }
        PyObject *pValue = PyObject_CallObject(pFunc, pArgs);
        Py_DECREF(pArgs);
        if (pValue != NULL) {
            outValue = pValue;
        } else {
            Py_DECREF(pFunc);
            PyErr_Print();
            fprintf(stderr,"swiftvim error: call failed\n");
            return outValue;
        }
    } else {
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        fprintf(stderr, "swiftvim error: cannot find function \"(some)\"\n");
    }

    return outValue;
}

void *swiftvim_command(const char *command) {
    return swiftvim_call("vim", "command", command);
}

void *swiftvim_eval(const char *eval) {
    return swiftvim_call("vim", "eval", eval);
}

// TODO: Do these need GIL locks?
void *swiftvim_decref(void *value) {
    Py_DECREF(value);
    return value;
}

void *swiftvim_incref(void *value) {
    Py_INCREF(value);
    return value;
}

const char *swiftvim_asstring(void *value) {
    if (value == NULL) {
        return "";
    }
    PyGILState_STATE gstate = PyGILState_Ensure();
    const char *v = SPyString_AsString(value);
    PyGILState_Release(gstate);
    return v;
}

int swiftvim_asint(void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    int v = PyLong_AsLong(value);
    PyGILState_Release(gstate);
    return v;
}

int swiftvim_list_size(void *list) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    int v = PySequence_Size(list);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_list_set(void *list, size_t i, void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PySequence_SetItem(list, i, value);
    PyGILState_Release(gstate);
}

void *swiftvim_list_get(void *list, size_t i) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    /// Return a borrowed reference
    void *v = PySequence_GetItem(list, i);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_list_append(void *list, void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyList_Append(list, value);
    PyGILState_Release(gstate);
}

// MARK - Dict

int swiftvim_dict_size(void *dict) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    int v = PyDict_Size(dict);
    PyGILState_Release(gstate);
    return v;
}

void *swiftvim_dict_keys(void *dict) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    // Return value: New reference
    void *v = PyDict_Keys(dict);
    PyGILState_Release(gstate);
    return v;
}

void *swiftvim_dict_values(void *dict) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    // Return value: New reference
    void *v = PyDict_Items(dict);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_dict_set(void *dict, void *key, void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyDict_SetItem(dict, key, value);
    PyGILState_Release(gstate);
}

void *swiftvim_dict_get(void *dict, void *key) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    /// Return a borrowed reference
    void *v = PyDict_GetItem(dict, key);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_dict_setstr(void *dict, const char *key, void *value) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyDict_SetItemString(dict, key, value);
    PyGILState_Release(gstate);
}

void *swiftvim_dict_getstr(void *dict, const char *key) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    /// Return a borrowed reference
    void *v = PyDict_GetItemString(dict, key);
    PyGILState_Release(gstate);
    return v;
}

// MARK - Tuples

void *_Nonnull swiftvim_tuple_get(void *_Nonnull tuple, int idx) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    /// Return a borrowed reference
    void *v = PyTuple_GetItem(tuple, idx);
    PyGILState_Release(gstate);
    return v;
}

void swiftvim_initialize() {
    Py_Initialize();
    if(!PyEval_ThreadsInitialized()) {
        PyEval_InitThreads();
    }

#ifdef SPMVIM_LOADSTUB_RUNTIME
    // For unit tests, we fake out the vim module
    // to make the tests as pure as possible.
    // Assume that tests are running from the source root
    // We could do something better.
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL)
        fprintf(stderr, "GarbPWD");
    strcat(cwd, "/Tests/VimInterfaceTests/MockVimRuntime/");
    fprintf(stderr, "Adding test import path: %s \n", cwd);
    PyObject* sysPath = PySys_GetObject((char*)"path");
    PyObject* programName = SPyString_FromString(cwd);
    PyList_Append(sysPath, programName);
    Py_DECREF(programName);
#endif
}

void swiftvim_finalize() {
    Py_Finalize();
}

