#lang crook
{:= B C D0 D1 E0 E1}
(provide {:> E0} compile-op0 compile-op1)
(require "ast.rkt")
{:> D0} (require "types.rkt")
(require a86/ast)

(define rax 'rax)
{:> E0} (define rdi 'rdi) {:> E0} ; arg
{:> D0} (define r9 'r9)   {:> E0} ; scratch

{:> E0} ;; Op0 -> Asm
{:> E0}
(define (compile-op0 p)
  (match p
    ['void      (seq (Mov rax (value->bits (void))))]
    ['read-byte (seq (Call 'read_byte))]
    ['peek-byte (seq (Call 'peek_byte))]))

;; Op1 -> Asm
(define (compile-op1 p)
  (match p
    {:> B D0}  ['add1 (Add rax 1)]
    {:> B D0}  ['sub1 (Sub rax 1)]
    {:> D0 E1} ['add1 (Add rax (value->bits 1))]
    {:> E1}    ['add1
                (seq (assert-integer rax)
                     (Add rax (value->bits 1)))]
    {:> D0 E1} ['sub1 (Sub rax (value->bits 1))]
    {:> E1}    ['sub1
                (seq (assert-integer rax)
                     (Sub rax (value->bits 1)))]
    {:> D0}    ['zero?
                {:> D0 D1}
                (seq (Cmp rax 0)
                     (Mov rax (value->bits #f))
                     (Mov r9  (value->bits #t))
                     (Cmove rax r9))
                {:> D1}
                (seq {:> E1} (assert-integer rax)
                     (Cmp rax 0)
                     if-equal)]
    {:> D1}   ['char?
               (seq (And rax mask-char)
                    (Cmp rax type-char)
                    if-equal)]
    {:> D1}   ['char->integer
               (seq {:> E1} (assert-char rax)
                    (Sar rax char-shift)
                    (Sal rax int-shift))]
    {:> D1}   ['integer->char
               (seq {:> E1} (assert-codepoint)
                    (Sar rax int-shift)
                    (Sal rax char-shift)
                    (Xor rax type-char))]
    {:> E0}   ['eof-object?
               (seq (Cmp rax (value->bits eof))
                    if-equal)]
    {:> E0}   ['write-byte
               (seq {:> E1} assert-byte
                    (Mov rdi rax)
                    (Call 'write_byte))]))

{:> D1} ;; -> Asm
{:> D1} ;; set rax to #t or #f if comparison flag is equal
{:> D1}
(define if-equal
  (seq (Mov rax (value->bits #f))
       (Mov r9  (value->bits #t))
       (Cmove rax r9)))

{:> E1}
(define (assert-type mask type)
  (λ (arg)
    (seq (Mov r9 arg)
         (And r9 mask)
         (Cmp r9 type)
         (Jne 'err))))

{:> E1}
(define (type-pred mask type)
  (seq (And rax mask)
       (Cmp rax type)
       (if-equal)))

{:> E1}
(define assert-integer
  (assert-type mask-int type-int))
{:> E1}
(define assert-char
  (assert-type mask-char type-char))

{:> E1}
(define (assert-codepoint)
  (let ((ok (gensym)))
    (seq (assert-integer rax)
         (Cmp rax (value->bits 0))
         (Jl 'err)
         (Cmp rax (value->bits 1114111))
         (Jg 'err)
         (Cmp rax (value->bits 55295))
         (Jl ok)
         (Cmp rax (value->bits 57344))
         (Jg ok)
         (Jmp 'err)
         (Label ok))))

{:> E1}
(define assert-byte
  (seq (assert-integer rax)
       (Cmp rax (value->bits 0))
       (Jl 'err)
       (Cmp rax (value->bits 255))
       (Jg 'err)))