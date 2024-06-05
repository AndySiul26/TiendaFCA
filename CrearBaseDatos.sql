-- Database: tienda

-- DROP DATABASE IF EXISTS tienda;

CREATE DATABASE tienda
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Mexico.1252'
    LC_CTYPE = 'Spanish_Mexico.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE tienda
    IS 'Base de datos para una tienda, proyecto para asignatura Base de Datos FCA UNAM';


-- Table: public.clientes

-- DROP TABLE IF EXISTS public.clientes;

CREATE TABLE IF NOT EXISTS public.clientes
(
    id integer NOT NULL DEFAULT nextval('clientes_id_seq'::regclass),
    nombre character varying(50) COLLATE pg_catalog."default" NOT NULL,
    apellido_paterno character varying(50) COLLATE pg_catalog."default" NOT NULL,
    apellido_materno character varying(50) COLLATE pg_catalog."default" NOT NULL,
    rfc character varying(15) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT clientes_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.clientes
    OWNER to postgres;

-- Table: public.productos

-- DROP TABLE IF EXISTS public.productos;

CREATE TABLE IF NOT EXISTS public.productos
(
    id integer NOT NULL DEFAULT nextval('productos_id_seq'::regclass),
    nombre character varying(50) COLLATE pg_catalog."default" NOT NULL,
    descripcion character varying(200) COLLATE pg_catalog."default" NOT NULL,
    precio numeric(10,2) NOT NULL,
    cantidad integer NOT NULL,
    sku character varying(20) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT pk_productos_id UNIQUE (id),
    CONSTRAINT check_cantidad_no_negativa CHECK (cantidad >= 0),
    CONSTRAINT check_precio_positivo CHECK (precio > 0::numeric)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.productos
    OWNER to postgres;
-- Index: idx_descripcion_gin

-- DROP INDEX IF EXISTS public.idx_descripcion_gin;

CREATE INDEX IF NOT EXISTS idx_descripcion_gin
    ON public.productos USING gin
    (to_tsvector('spanish'::regconfig, descripcion::text))
    TABLESPACE pg_default;
-- Index: idx_sku_unique

-- DROP INDEX IF EXISTS public.idx_sku_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_sku_unique
    ON public.productos USING btree
    (sku COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Table: public.ordenes

-- DROP TABLE IF EXISTS public.ordenes;

CREATE TABLE IF NOT EXISTS public.ordenes
(
    id integer NOT NULL DEFAULT nextval('ordenes_id_seq'::regclass),
    cliente_id integer NOT NULL,
    producto_id integer NOT NULL,
    cantidad integer NOT NULL,
    fecha timestamp without time zone DEFAULT now(),
    CONSTRAINT ordenes_pkey PRIMARY KEY (id),
    CONSTRAINT ordenes_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES public.clientes (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT ordenes_producto_id_fkey FOREIGN KEY (producto_id)
        REFERENCES public.productos (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE RESTRICT,
    CONSTRAINT check_cantidad_positiva CHECK (cantidad > 0)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ordenes
    OWNER to postgres;

-- Trigger: validar_cantidad_trigger

-- DROP TRIGGER IF EXISTS validar_cantidad_trigger ON public.ordenes;

CREATE OR REPLACE TRIGGER validar_cantidad_trigger
    BEFORE INSERT
    ON public.ordenes
    FOR EACH ROW
    EXECUTE FUNCTION public.validar_cantidad_producto();