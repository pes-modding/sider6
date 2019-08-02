;------------------------------------------
;Descr  : hooking utils
;
;Small functions to help with hooking
;Typically, they would call a function
;from sider, which does all the actual work
;------------------------------------------

extern sider_read_file:proc
extern sider_get_size:proc
extern sider_mem_copy:proc
extern sider_lookup_file:proc
extern sider_set_team_id:proc
extern sider_set_settings:proc
extern sider_trophy_check:proc
extern sider_context_reset:proc
extern sider_free_select:proc
extern sider_trophy_table:proc
extern sider_ball_name:proc
extern sider_stadium_name:proc
extern sider_def_stadium_name:proc
extern sider_set_stadium_choice:proc
extern sider_check_kit_choice:proc
extern sider_data_ready:proc
extern sider_kit_status:proc
extern sider_set_team_for_kits:proc
extern sider_clear_team_for_kits:proc
extern sider_loaded_uniparam:proc

.code
sider_read_file_hk proc

        mov     rax,[rsp+28h]
        sub     rsp,38h
        mov     [rsp+20h],rax
        mov     [rsp+28h],r12
        call    sider_read_file
        mov     r12,[rsp+28h]
        add     rsp,38h
        ret

sider_read_file_hk endp

sider_get_size_hk proc

        sub     rsp,28h
        mov     [rsp+20h],rdx
        mov     rcx,rsi
        mov     rdx,rbx
        call    sider_get_size
        mov     rcx,qword ptr [rdi+1d8h]
        mov     eax,1
        mov     rdx,[rsp+20h]
        add     rsp,28h
        ret

sider_get_size_hk endp

sider_extend_cpk_hk proc

        mov     rax,1000000000000000h
        mov     qword ptr [rdi+8],rax
        mov     qword ptr [r13],rdi
        ret

sider_extend_cpk_hk endp

sider_mem_copy_hk proc

        push    r12
        sub     rsp,20h
        add     r8,r10
        call    sider_mem_copy
        mov     qword ptr [rdi+10h],rbx
        add     rsp,20h
        pop     r12
        ret

sider_mem_copy_hk endp

sider_lookup_file_hk proc

        push    rax
        sub     rsp,20h
        call    sider_lookup_file
        lea     rcx,qword ptr [rdi+110h]
        mov     r8,rsi
        lea     rdx,qword ptr [rsp+50h]
        add     rsp,20h
        pop     rax
        ret

sider_lookup_file_hk endp

;000000014126DF00 | 49 63 00                           | movsxd rax,dword ptr ds:[r8]            | prep to write team info
;000000014126DF03 | 83 F8 02                           | cmp eax,2                               |
;000000014126DF06 | 7D 16                              | jge pes2018.14126DF1E                   |
;000000014126DF08 | 4C 69 C0 20 05 00 00               | imul r8,rax,520                         |
;000000014126DF0F | 48 81 C1 04 01 00 00               | add rcx,104                             |
;000000014126DF16 | 49 03 C8                           | add rcx,r8                              |
;000000014126DF19 | E9 D2 72 7D FF                     | jmp pes2018.140A451F0                   |
;000000014126DF1E | C3                                 | ret                                     |

sider_set_team_id_hk proc

        mov     rdx,[rsp+8h]
        push    r9
        push    r10
        push    r11
        sub     rsp,40h
        movsxd  rax,dword ptr [r8]
        mov     [rsp+30h],rax
        cmp     eax,2
        jge     done
        imul    r8,rax,5ech
        add     rcx,118h
        add     rcx,r8
        mov     [rsp+20h],rcx
        mov     [rsp+28h],r8
        call    sider_set_team_id
        mov     rcx,[rsp+20h]
        mov     r8,[rsp+28h]
        mov     rax,[rsp+30h]
done:   add     rsp,40h
        pop     r11
        pop     r10
        pop     r9
        ret

sider_set_team_id_hk endp

;000000014D930169 | 0F B6 82 97 00 00 00          | movzx eax,byte ptr ds:[rdx+97]           |
;000000014D930170 | 88 81 97 00 00 00             | mov byte ptr ds:[rcx+97],al              |
;000000014D930176 | 8B 82 98 00 00 00             | mov eax,dword ptr ds:[rdx+98]            |
;000000014D93017C | 89 81 98 00 00 00             | mov dword ptr ds:[rcx+98],eax            |
;000000014D930182 | 48 89 C8                      | mov rax,rcx                              | set_settings
;000000014D930185 | C3                            | ret                                      |

sider_set_settings_hk proc

        pushfq
        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,20h
        movzx   eax,byte ptr [rdx+97h]
        mov     byte ptr [rcx+97h],al
        mov     eax,dword ptr [rdx+98h]
        mov     dword ptr [rcx+98h],eax
        call    sider_set_settings
        add     rsp,20h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        popfq
        ret

sider_set_settings_hk endp

sider_trophy_check_hk proc

        push    rax
        sub     rsp,20h
        mov     ecx,dword ptr [rbp+488h]
        call    sider_trophy_check
        mov     ecx,eax
        and     r14b,1
        sar     esi,1
        add     rsp,20h
        pop     rax
        ret

sider_trophy_check_hk endp

sider_context_reset_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        mov     qword ptr [rbx+84h],rcx
        mov     qword ptr [rbx+21f74h],0ffffffffh
        call    sider_context_reset
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        ret

sider_context_reset_hk endp

sider_free_select_hk proc

        push    rax
        sub     rsp,20h
        movsd   xmm0,qword ptr [rax]
        movsd   qword ptr [rbx+0a4h],xmm0
        lea     rcx,[rbx+0a4h]
        call    sider_free_select
        add     rsp,20h
        pop     rax
        ret

sider_free_select_hk endp

sider_trophy_table_hk proc

        push    rax
        push    r11
        sub     rsp,28h
        mov     rbx,qword ptr [r11+30h]
        mov     rsi,qword ptr [r11+38h]
        mov     rdi,qword ptr [r11+40h]
        lea     rcx,[rsp+40h]
        call    sider_trophy_table
        add     rsp,28h
        pop     r11
        pop     rax
        ret

sider_trophy_table_hk endp

;000000014D9A071F | 49 83 C8 FF                          | or r8,FFFFFFFFFFFFFFFF           |
;000000014D9A0723 | 49 FF C0                             | inc r8                           |
;000000014D9A0726 | 42 80 3C 02 00                       | cmp byte ptr ds:[rdx+r8],0       |
;000000014D9A072B | 75 F6                                | jne pes2019.14D9A0723            |
;000000014D9A072D | 48 89 C1                             | mov rcx,rax                      | rcx:dst,rdx:src,r8:len

sider_ball_name_hk proc

        sub     rsp,38h
        mov     [rsp+20h],rcx
        mov     [rsp+28h],rdx
        mov     rcx,rdx
        call    sider_ball_name
        mov     rdx,rax
        mov     rcx,[rsp+20h]
        or      r8,0ffffffffffffffffh
next:   inc     r8
        cmp     byte ptr [rdx+r8],0
        jne     next
        mov     rax,[rsp+40h]
        mov     rcx,rax
        add     rsp,38h
        ret

sider_ball_name_hk endp

;000000014CFE651F | 49 83 C8 FF                  | or r8,FFFFFFFFFFFFFFFF                 |
;000000014CFE6523 | 49 FF C0                     | inc r8                                 |
;000000014CFE6526 | 42 80 3C 02 00               | cmp byte ptr ds:[rdx+r8],0             | rdx+r8*1:"Allianz Parque"
;000000014CFE652B | 75 F6                        | jne pes2019.14CFE6523                  |
;000000014CFE652D | 48 89 C1                     | mov rcx,rax                            | rcx:dst,rdx:src,r8:len

sider_stadium_name_hk proc

        sub     rsp,38h
        mov     [rsp+20h],rcx
        mov     [rsp+28h],rdx
        ;mov     rcx,rdx
        call    sider_stadium_name
        mov     rdx,rax
        mov     rcx,[rsp+20h]
        or      r8,0ffffffffffffffffh
next:   inc     r8
        cmp     byte ptr [rdx+r8],0
        jne     next
        mov     rax,[rsp+40h]
        mov     rcx,rax
        add     rsp,38h
        ret

sider_stadium_name_hk endp

;000000014D33447D | 48 85 C0                             | test rax,rax                           |
;000000014D334480 | 74 0D                                | je pes2019.14D33448F                   |
;000000014D334482 | 48 89 F2                             | mov rdx,rsi                            |
;000000014D334485 | 48 89 C1                             | mov rcx,rax                            |
;000000014D334488 | E8 63 C4 C4 F4                       | call pes2019.141F808F0                 |
;000000014D33448D | EB 12                                | jmp pes2019.14D3344A1                  |
;000000014D33448F | 45 31 C0                             | xor r8d,r8d                            |
;000000014D334492 | 48 8D 15 E9 F0 1F F5                 | lea rdx,qword ptr ds:[142533582]       |
;000000014D334499 | 48 89 F1                             | mov rcx,rsi                            |
;000000014D33449C | E8 6F E9 17 F3                       | call pes2019.1404B2E10                 |

sider_def_stadium_name_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        call    sider_def_stadium_name
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        ret

sider_def_stadium_name_hk endp

sider_set_stadium_choice_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        call    sider_set_stadium_choice
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        ret

sider_set_stadium_choice_hk endp

;000000014A382487 | 49 89 06                        | mov qword ptr ds:[r14],rax             | a little before kit choice is read
;000000014A38248A | 41 C6 87 FE FF FF FF 01         | mov byte ptr ds:[r15-2],1              |
;000000014A382492 | 41 C6 07 00                     | mov byte ptr ds:[r15],0                |

sider_check_kit_choice_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        push    r15
        sub     rsp,20h
        mov     rcx,rdi   ;mis - match info struct
        mov     rdx,rbx   ;0/1 - home/away
        call    sider_check_kit_choice
        add     rsp,20h
        pop     r15
        mov     byte ptr [r15-2],1
        mov     byte ptr [r15],0
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        ret

sider_check_kit_choice_hk endp

;000000014000E877 | C7 43 18 07 00 00 00            | mov dword ptr ds:[rbx+18],7            |
;000000014000E87E | 89 43 6C                        | mov dword ptr ds:[rbx+6C],eax          |
;000000014000E881 | 83 7B 18 06                     | cmp dword ptr ds:[rbx+18],6            |
;000000014000E885 | 75 08                           | jne pes2019.14000E88F                  |
;...
;000000014000E8A0 | 48 8B 5C 24 30                  | mov rbx,qword ptr ss:[rsp+30]          |
;000000014000E8A5 | 48 83 C4 20                     | add rsp,20                             |
;000000014000E8A9 | 5D                              | pop rbp                                |
;000000014000E8AA | C3                              | ret                                    |

sider_data_ready_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,20h   ; we get here via jmp, so stack already aligned
        mov     rcx,rbx   ; buffer structure
        call    sider_data_ready
        add     rsp,20h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        mov     rbx,qword ptr [rsp+30h]  ; original replaced code
        add     rsp,20h
        pop     rbp
        ret

sider_data_ready_hk endp

;00000001505F09CC | 44 0F B6 4B 4E                     | movzx r9d,byte ptr ds:[rbx+4E]       |
;00000001505F09D1 | 44 0F B6 43 4D                     | movzx r8d,byte ptr ds:[rbx+4D]       |
;00000001505F09D6 | 0F B6 53 4C                        | movzx edx,byte ptr ds:[rbx+4C]       |

sider_kit_status_hk proc

        push    rcx
        push    r10
        push    r11
        push    rax
        sub     rsp,28h
        mov     rcx,rbx
        mov     rdx,rax
        call    sider_kit_status
        movzx   r9d, byte ptr [rbx+4eh]
        movzx   r8d, byte ptr [rbx+4dh]
        movzx   rdx, byte ptr [rbx+4ch]
        add     rsp,28h
        pop     rax
        pop     r11
        pop     r10
        pop     rcx
        ret

sider_kit_status_hk endp

;0000000150A7259F | 31 C2                              | xor edx,eax                          |
;0000000150A725A1 | 81 E2 FF 3F 00 00                  | and edx,3FFF                         |
;0000000150A725A7 | 31 C2                              | xor edx,eax                          |
;0000000150A725A9 | 41 89 51 10                        | mov dword ptr ds:[r9+10],edx         | set team id (for kits)

sider_set_team_for_kits_hk proc

        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        xor     edx,eax
        and     edx,3fffh
        xor     edx,eax
        mov     dword ptr [r9+10h],edx
        mov     rcx,rbx
        add     r9,10h
        call    sider_set_team_for_kits
        mov     rcx,3fffh
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        ret

sider_set_team_for_kits_hk endp

;0000000150A74D73 | 89 8A FC FF FF FF                  | mov dword ptr ds:[rdx-4],ecx         | clear (reset) team id (for kits)
;0000000150A74D79 | C7 42 18 FF FF 00 00               | mov dword ptr ds:[rdx+18],FFFF       |
;0000000150A74D80 | C7 42 30 FF FF FF FF               | mov dword ptr ds:[rdx+30],FFFFFFFF   |

sider_clear_team_for_kits_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        mov     dword ptr [rdx-4h],ecx
        mov     dword ptr [rdx+18h],0ffffh
        mov     rcx,rbx
        sub     rdx,4
        call    sider_clear_team_for_kits
        mov     rax,3fffh
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        ret

sider_clear_team_for_kits_hk endp

;00000001509C77F6 | 45 31 C0                           | xor r8d,r8d                          |
;00000001509C77F9 | 41 8D 50 20                        | lea edx,qword ptr ds:[r8+20]         |
;00000001509C77FD | 48 8D 4C 24 40                     | lea rcx,qword ptr ss:[rsp+40]        |

sider_loaded_uniparam_hk proc

        push    rcx
        push    rdx
        push    r8
        push    r9
        push    r10
        push    r11
        sub     rsp,28h
        mov     rcx,rax
        call    sider_loaded_uniparam
        mov     [rsi+38h],rax
        add     rsp,28h
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rdx
        pop     rcx
        xor     r8d,r8d
        lea     edx,qword ptr [r8+20h]
        lea     rcx,qword ptr [rsp+48h]
        ret

sider_loaded_uniparam_hk endp

end
