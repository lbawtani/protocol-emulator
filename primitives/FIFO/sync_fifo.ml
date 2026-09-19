(** Single-clock (synchronous) FIFO with registered read data. *)

open Hardcaml
open Signal

(* Smallest [b] such that [n] values can be addressed with [b] bits. *)
let address_bits_for n =
  let rec loop b = if 1 lsl b >= n then b else loop (b + 1) in
  loop 1

module Make (Config : sig
    val data_width : int
    val depth : int
  end) =
struct
  open Config

  let log_depth = address_bits_for depth

  module I = struct
    type 'a t =
      { clock : 'a
      ; clear : 'a
      ; wr : 'a
      ; d : 'a [@bits data_width]
      ; rd : 'a
      }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t =
      { q : 'a [@bits data_width]
      ; full : 'a
      ; empty : 'a
      }
    [@@deriving hardcaml]
  end

  let create (i : Signal.t I.t) : Signal.t O.t =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    let wptr = wire log_depth in
    let wptr_next = wptr +:. 1 in
    let rptr = wire log_depth in
    let full = wptr_next ==: rptr in
    let empty = wptr ==: rptr in
    let write_enable = i.wr &: ~:full in
    let read_enable = i.rd &: ~:empty in
    let mem =
      Ram.create
        ~collision_mode:Write_before_read
        ~size:depth
        ~write_ports:
          [| { write_clock = i.clock
             ; write_data = i.d
             ; write_enable
             ; write_address = wptr
             }
          |]
        ~read_ports:[| { read_clock = i.clock; read_enable; read_address = rptr } |]
        ()
    in
    wptr <-- reg spec ~enable:write_enable wptr_next;
    rptr <-- reg spec ~enable:read_enable (rptr +:. 1);
    { O.q = mem.(0); full; empty }
end
