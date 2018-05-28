// Main vimscript methods
void *_Nullable swiftvim_command(const char *_Nonnull command);
void *_Nullable swiftvim_eval(const char *_Nonnull eval);

// Internally, the API uses reference counting
void *_Nullable swiftvim_decref(void *_Nullable value); 
void *_Nullable swiftvim_incref(void *_Nullable value);

// Value extraction
const char *_Nullable swiftvim_asstring(void *_Nullable value);
int swiftvim_asint(void *_Nullable value);

// Bootstrapping
// Note: These methods are only for testing purposes
void swiftvim_initialize();
void swiftvim_finalize();
void *_Nullable swiftvim_call(const char *_Nonnull module, const char *_Nonnull method, const char *_Nonnull str); 
