# libcobc bindings!

With this bindings, it's possible to call cobol programs from your ruby programs.

For doing so, the cobol program must be compiled as a dynamic module.
There must be a file called `say.so`.

There is a shell script called `build.sh` wich is configured to call the compiler with correct parameter.

Function `cob_init()` must be called before calling any other cobol callings.



## Important structs

```c
/* Field attribute structure */

typedef struct {
	unsigned char	type;		/* Field type */
	unsigned char	digits;		/* Digit count */
	signed char	scale;		/* Field scale */
	unsigned char	flags;		/* Field flags */
	const char	*pic;		/* Pointer to picture string */
} cob_field_attr;

/* Field structure */

typedef struct {
	size_t			size;		/* Field size */
	unsigned char		*data;		/* Pointer to field data */
	const cob_field_attr	*attr;		/* Pointer to attribute */
} cob_field;

/* Module structure */

struct cob_module {
	struct cob_module		*next;
	const unsigned char		*collating_sequence;
	cob_field			*crt_status;
	cob_field			*cursor_pos;
	cob_field			**cob_procedure_parameters;
	const unsigned char		display_sign;
	const unsigned char		decimal_point;
	unsigned char			currency_symbol;
	const unsigned char		numeric_separator;
	const unsigned char		flag_filename_mapping;
	const unsigned char		flag_binary_truncate;
	const unsigned char		flag_pretty_display;
	const unsigned char		spare8;
	char				*program_id;
};
```


