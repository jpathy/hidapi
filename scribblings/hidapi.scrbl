#lang scribble/manual
@require[@for-label[hidapi
                    racket/base
                    racket/contract]]

@title{hidapi}
@author{Jiten K. Pathy}

@defmodule[hidapi]

This package provides bindings to @link["https://github.com/libusb/hidapi"]{hidapi} library.
The library name is searched in the order:@linebreak{}
@filepath{libhidapi} @filepath{libhidapi-libusb} @filepath{libhidapi-hidraw}

@defstruct*[hid-device-info ([path                path?]
                             [vendor-id           integer?]
                             [product-id          integer?]
                             [serial-number       string?]
                             [release-number      integer?]
                             [manufacturer-string string?]
                             [product-string      string?]
                             [usage-page          integer?]
                             [usage               integer?]
                             [interface-number    integer?])]{
 A racket structure corresponding to foreign structure @racket[hid_device_info].}

@defproc[(hid-device? [d any/c]) boolean?]{
 Returns @racket[#t] if it is a @racket[hid_device], @racket[#f] otherwise.}

@defproc[(hid-init) void?]{Binding to @racket[hid_init]. Might raise exception @racket[exn:fail].}

@defproc[(hid-exit) void?]{Binding to @racket[hid_exit]. Might raise exception @racket[exn:fail].}

@defproc[(hid-enumerate [#:vendor-id v integer? 0]
                        [#:product-id p integer? 0]) (listof hid-device-info?)]{
 High-level safe binding to @racket[hid_enumerate].
 The foreign allocated data is free'd with @racket[hid_free_enumeration].
}

@defproc[(hid-open [#:vendor-id v integer?]
                   [#:product-id p integer?]
                   [#:serial-number s string?]) (or/c hid-device? #f)]{Binding to @racket[hid_open].}

@defproc[(hid-open-path [p path?]) (or/c hid-device? #f)]{Binding to @racket[hid_open_path].}

@defproc[(hid-set-nonblocking [d hid-device?] [b boolean?]) void?]{
 Binding to @racket[hid_set_nonblocking]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-close [d hid-device?]) void?]{Binding to @racket[hid_close].}

@defproc[(hid-write [d hid-device?]
                    [bstr bytes?]
                    [size integer?]) integer?]{
 Binding to @racket[hid_write]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-write-full [d hid-device?]
                         [bstr bytes?]) integer?]{
 Same as @racket[(hid-write bstr (bytes-length bstr))].
}

@defproc[(hid-read [d hid-device?]
                   [bstr bytes?]
                   [size integer?]) integer?]{
 Binding to @racket[hid_read]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-read-bytes [d hid-device?]
                         [size integer?]) bytes?]{
 Same as @racket[(hid-read d (make-bytes size) size)],
 returns the created bytestring.
}

@defproc[(hid-read-timeout [d hid-device?]
                           [bstr bytes?]
                           [size integer?]
                           [millis integer?]) integer?]{
 Binding to @racket[hid_read_timeout]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-read-bytes/timeout [d hid-device?]
                                 [size integer?]
                                 [millis integer?]) bytes?]{
 Binding to @racket[(hid-read-timeout d (make-bytes size) size millis)],
 returns the created bytestring.
}

@defproc[(hid-get-feature-report [d hid-device?]
                                 [bstr bytes?]
                                 [size integer?]) integer?]{
 Binding to @racket[hid_get_feature_report]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-send-feature-report [d hid-device?]
                                  [bstr bytes?]
                                  [size integer?]) integer?]{
 Binding to @racket[hid_send_feature_report]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-get-manufacturer-string [d hid-device?]
                                      [size integer?]) string?]{
 Binding to @racket[hid_get_manufacturer_string]. Might raise exception @racket[exn:fail].
}


@defproc[(hid-get-product-string [d hid-device?]
                                 [size integer?]) string?]{
 Binding to @racket[hid_get_product_string]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-get-serial-number-string [d hid-device?]
                                       [size integer?]) string?]{
 Binding to @racket[hid_get_serial_number_string]. Might raise exception @racket[exn:fail].
}

@defproc[(hid-get-indexed-string [d hid-device?]
                                 [idx integer?]
                                 [size integer?]) string?]{
 Binding to @racket[hid_get_indexed_string]. Might raise exception @racket[exn:fail].
}