;
;   cghelper - 简单的学生成绩统计工具。
;             （汇编语言程序设计课程 上机大作业）
;
;   1953610    7/24/2020
;

.model compact
.stack 64

.data

    ; 用于保存数据的内存空间

    Stu         Struc
    recname     db 10 dup(?), '$'
    id          db 7 dup(?), '$'
    score       db 0
    Stu         Ends

    recpool     Stu 60 dup(<>)
    reccount    db 0

    ; 输入缓冲区

    infield     db ?, ?, 14 dup(?)

    ; 提示文本

    emptyln     db 0dh, 0ah, '$'

    mnmsg_cpt   db "# Class Grade Helper", '$'
    mnmsg_cpr   db " (c) 2020 strear.", 0dh, 0ah, '$'

    opmsg_pmt   db "  Ready: Choose an operation.", 0dh, 0ah, '$'
    opmsg       db 0ah
                db "  1, Input record(s).  2, List all.", 0dh, 0ah
                db "  3, Show analysis.    4, Clear.", 0dh, 0ah
                db "  0, Quit.", 0dh, 0ah, 0ah, '$'

    selpmpt     db "  => $"
    pausemsg    db 0dh, "  Enter to continue...$"

    ; 提示文本：输入记录

    inmsg_askc  db "  How many records in total? $"

    inmsgprt0   db "  Enter info required for student #$"
    inmsgprt1   db ".", 0dh, 0ah, 0ah, '$'
    inmsg_n     db "    Name | $"
    inmsg_i     db "      ID | $"
    inmsg_s     db "   Score | $"
    inmsg_d     db 0ah, "  * Record added.", 0dh, 0ah, '$'

    inerr_num   db "  * Please enter a number below. Try again.", 0dh, 0ah, '$'
    inerr_score db "  * Please enter a number below in [0, 100]. Try again.", 0dh, 0ah, '$'
    inerr_getc  db "  * Can't save so many records. Try again.", 0dh, 0ah, '$'

    clmsg       db "  * All records are cleared.", 0dh, 0ah, '$'

    ; 提示文本：列出记录

    lsmsg_hdr   db "   ID      Name       Score", 0dh, 0ah
                db "   ------- ---------- -----$"

    lsmsg_cnt0  db 0dh, 0ah, "  * Totally $"
    lsmsg_cnt1  db " record(s).", 0dh, 0ah, '$'

    ; 提示文本：分析记录

    azerr_empt  db "  * Currently no records. Enter some and try again.", 0dh, 0ah, '$'
    azmsg_cnt0  db "  * Totally $"
    azmsg_cnt1  db " score records calculated.", 0dh, 0ah, 0ah
                db "  * Students in all segments counts as follows:", 0dh, 0ah, 0ah, '$'
    azmsg_ex    db "    Excellent: $"
    azmsg_gd    db "         Good: $"
    azmsg_md    db "       Medium: $"
    azmsg_ps    db "         Pass: $"
    azmsg_fl    db "         Fail: $"
    azmsg_ab    db "       Absent: $"
    scmsg_prt0  db " total, $"
    scmsg_prt1  db "%.", 0dh, 0ah, '$'
    azmsg_max   db 0dh, 0ah, "  * The highest score is $"
    azmsg_min   db ", lowest $"
    azmsg_avg   db ", and the average $"
    azmsg_end   db ".", 0dh, 0ah, '$'

.code

    ; 主程序

    Entry:
        push ds                 ; 返回地址入栈，用于正常退出
        xor ax, ax
        push ax


        mov ax, @data           ; 初始化数据寄存器
        mov ds, ax
        mov es, ax

        call putbanner          ; 开始运行，显示程序名称

    .main_cycle:
        call putmenu            ; 显示菜单
        call getop              ; 请求操作

        test bx, bx
        jz .main_exit
        call word ptr CS:optcase[bx-2]

        lea dx, emptyln
        call print
        call pause
        jmp .main_cycle

    .main_exit:                 ; 正常退出
        retf

    optcase     dw op_input, op_list, op_analyze, op_clear

    putbanner:
        mov bl, 0fh
        lea dx, mnmsg_cpt
        call printc

        mov bl, 08h
        lea dx, mnmsg_cpr
        call printc
        ret

    putmenu:
        mov bl, 0ch
        lea dx, opmsg_pmt
        call printc

        mov bl, 07h
        lea dx, opmsg
        call printc
        ret

    getop:
        mov bl, 09h
        lea dx, selpmpt
        call printc

    .getop_cycle:               ; 提示用户选择一个选项
        mov ah, 08h             ; 读一个输入
        int 21h

        mov dl, al              ; 选项序数
        sub al, '0'
        jl .getop_cycle
        cmp al, 4
        jg .getop_cycle

        xor ah, ah              ; 找出该功能的入口地址
        add al, al
        push ax

        mov ah, 02h             ; 回显输入
        int 21h

        mov bl, 07h             ; 清除输出颜色
        lea dx, emptyln
        call print
        call printc

        pop bx                  ; 返回选项
        ret



    ; 功能调用的封装

    print:
        mov ah, 09h
        int 21h
        ret

    printc:
        mov ax, 0900h
        mov bh, 0h
        mov cx, 07d0h
        int 10h
        call print
        ret

    pause:
        lea dx, pausemsg
        call print

        mov ah, 08h
        int 21h
        cmp al, 0dh
        jne pause

        mov ah, 02h
        mov dl, 0dh
        int 21h
        ret

    parsenum:
        mov dl, infield[1]
        xor dh, dh
        mov di, dx
        mov dl, 10

        xor ax, ax
        xor si, si
        jmp .parsen_loopin

    .parsen_loop:
        mul dl
        add al, infield[si+1]
        sub al, '0'

    .parsen_loopin:
        inc si
        cmp si, di
        jle .parsen_loop
        ret

    putdecal_right:             ; 十进制输出AL，右对齐
        push ax
        mov bx, 10
        jmp .putdecal_spc_loopin

    .putdecal_spc_loop:
        xor ah, ah
        div bl
        test al, al
        jnz .putdecal_spc_loopin

        push ax
        mov ah, 2h
        int 21h
        pop ax

    .putdecal_spc_loopin:
        loop .putdecal_spc_loop
        pop ax

    putdecal:                   ; 十进制输出AL（递归方法）
        mov bx, 10
        call .putdecal
        ret

    .putdecal:
        push ax
        xor ah, ah              ; 将数字分为AH和AL两部分
        div bl                  ; AL = 商, AH = 余数
        test al, al             ; 是前导0吗？
        je .pdec_digin          ; - 如果不是，显示该位余数
        call .putdecal          ; 继续处理商

    .pdec_digin:
        add ah, '0'
        mov dl, ah
        mov ah, 09h             ; 设置输出颜色
        mov cx, 01h
        int 10h
        mov ah, 02h             ; 输出数字
        int 21h
        pop ax
        ret

    input:
        call print              ; 输入提示语
        push dx

        lea dx, infield
        mov ah, 0ah
        int 21h

        pop dx
        call bx                 ; 检查输入
        jc input

        lea dx, emptyln
        call print
        ret

    inchk_num:
        mov cl, infield[1]      ; 检查非空
        test cl, cl
        jz inchk_bad

        xor ch, ch
        mov si, cx
        jmp .inchkn_loopin

    .inchkn_loop:
        mov al, infield[si+2]
        cmp al, '0'
        jnae .inchkn_fail
        cmp al, '9'
        jnbe .inchkn_fail

    .inchkn_loopin:
        dec si
        cmp si, 0
        jge .inchkn_loop
        jmp inchk_good

    .inchkn_fail:
        push dx
        lea dx, inerr_num
        call print
        pop dx
        jmp inchk_bad

    inchk_bad:
        stc
        ret

    inchk_good:
        clc
        ret



    ; 操作

    ; 输入

    op_input:
        lea dx, inmsg_askc      ; 确定本次输入数据总数
        lea bx, .inchk_getc
        mov infield, 3
        call input
        call .opin_prepcycle

        jmp .opin_newcycle

    .opin_cycle:
        push ax
        push cx

        lea dx, inmsgprt0       ; 提示即将输入的数据序数
        call print
        mov al, cl
        call putdecal
        lea dx, inmsgprt1
        call print

        call .opin_one          ; 输入一条数据
        add bp, size Stu

        pop cx
        pop ax

    .opin_newcycle:
        inc cx
        cmp cx, ax
        jle .opin_cycle

        mov reccount, al        ; 数据输入完毕，返回
        ret

    .inchk_getc:
        call inchk_num
        jc inchk_bad

        push dx
        call parsenum
        pop dx
        add al, reccount

        xor ah, ah
        mov di, ax
        cmp al, length recpool
        jbe inchk_good

        push dx
        lea dx, inerr_getc
        call print
        pop dx
        jmp inchk_bad

    .inchk_score:
        call inchk_num
        jc inchk_bad

        cmp cl, 3
        jb inchk_good

        cmp infield[2], '1'
        jb inchk_good
        ja .inchk_score_fail

        cmp infield[3], '0'
        ja .inchk_score_fail

        cmp infield[4], '0'
        ja .inchk_score_fail
        jmp inchk_good

    .inchk_score_fail:
        push dx
        lea dx, inerr_score
        call print
        pop dx
        jmp inchk_bad

    .opin_prepcycle:
        xor ah, ah
        mov al, reccount
        mov bl, size Stu
        mul bl
        mov bp, ax
        add bp, offset recpool

        mov ax, di
        xor ch, ch
        mov cl, reccount
        ret

    .opin_one:
        lea dx, inmsg_n         ; 姓名
        lea bx, inchk_good
        mov infield, size recname+1
        call input

        mov cl, infield+1       ; 从输入缓冲转移到数据区
        xor ch, ch
        lea si, infield+2
        mov di, bp
        add di, Stu.recname
        cld
        rep movsb

        mov al, ' '             ; 清空原有内容
        mov cl, size recname
        sub cl, infield+1
        rep stosb

        lea dx, inmsg_i         ; 学号
        lea bx, inchk_num
        mov infield, size id+1
        call input

        mov cl, infield+1       ; 从输入缓冲转移到数据区
        xor ch, ch
        lea si, infield+2
        mov di, bp
        add di, Stu.id+size id
        sub di, cx
        cld
        rep movsb

        mov al, ' '             ; 清空原有内容
        mov di, bp
        add di, Stu.id
        mov cl, size id
        sub cl, infield+1
        rep stosb

        lea dx, inmsg_s         ; 成绩
        lea bx, .inchk_score
        mov infield, 4
        call input

        call parsenum           ; 从输入缓冲转移到数据区
        mov DS:[bp+Stu.score], al

        lea dx, inmsg_d
        call print
        ret


    ; 清空

    op_clear:
        mov reccount, 0

        lea dx, clmsg
        call print

        ret


    ; 列表

    op_list:
        lea dx, lsmsg_hdr
        call print

        lea si, recpool
        xor cl, cl
        jmp .opls_newcycle

    .opls_cycle:
        mov dl, ' '             ; 输出空格
        mov ah, 2h
        rept 3
            int 21h
        endm

        lea dx, [si+Stu.id]     ; 学号
        call print

        mov dl, ' '             ; 输出空格
        mov ah, 2h
        int 21h

        lea dx, [si+Stu.recname]; 姓名
        call print

        mov dl, ' '             ; 输出空格
        mov ah, 2h
        int 21h
        int 21h

        mov al, [si+Stu.score]  ; 成绩
        push cx
        mov cx, 3
        call putdecal_right
        pop cx

        add si, size Stu

    .opls_newcycle:
        lea dx, emptyln
        call print

        inc cl
        mov al, cl
        xor ah, ah
        mov bl, 20              ; 当输出数据达到该值时，暂停一下
        div bl
        test ah, ah
        jnz .opls_nopause

        lea dx, emptyln
        call print
        call pause

    .opls_nopause:
        cmp cl, reccount
        jle .opls_cycle

        lea dx, lsmsg_cnt0      ; 列表完毕，显示数据总数
        call print

        mov al, reccount
        call putdecal

        lea dx, lsmsg_cnt1
        call print

        ret


    ; 统计

    op_analyze:
        cmp reccount, 0         ; 确认非空
        jnz .opaz_init

        lea dx, azerr_empt
        call print
        ret

        ; 存放临时数据
        .opaz_ex_c  db ?
        .opaz_gd_c  db ?
        .opaz_md_c  db ?
        .opaz_ps_c  db ?
        .opaz_fl_c  db ?
        .opaz_ab_c  db ?

        .opaz_max   db ?
        .opaz_min   db ?
        .opaz_sum   dw ?

    .opaz_init:
        mov .opaz_ex_c, 0
        mov .opaz_gd_c, 0
        mov .opaz_md_c, 0
        mov .opaz_ps_c, 0
        mov .opaz_fl_c, 0
        mov .opaz_ab_c, 0
        mov .opaz_max, -128
        mov .opaz_min, 127
        mov .opaz_sum, 0

        xor ah, ah
        mov al, reccount
        dec al
        mov bl, size Stu
        mul bl
        mov cx, ax

    .opaz_cycle:
        mov bx, cx
        mov al, recpool[bx].score
        xor ah, ah
        add .opaz_sum, ax

        cmp al, .opaz_max
        jng .opaz_notmax
        mov .opaz_max, al

    .opaz_notmax:
        test al, al
        jz .opaz_notmin
        cmp al, .opaz_min
        jnl .opaz_notmin
        mov .opaz_min, al

    .opaz_notmin:
        cmp ax, 90
        jnge .opaz_notex
        inc .opaz_ex_c
        jmp .opaz_newcycle

    .opaz_notex:
        cmp ax, 80
        jnge .opaz_notgd
        inc .opaz_gd_c
        jmp .opaz_newcycle

    .opaz_notgd:
        cmp ax, 70
        jnge .opaz_notmd
        inc .opaz_md_c
        jmp .opaz_newcycle

    .opaz_notmd:
        cmp ax, 60
        jnge .opaz_notps
        inc .opaz_ps_c
        jmp .opaz_newcycle

    .opaz_notps:
        test ax, ax
        jz .opaz_absent
        inc .opaz_fl_c
        jmp .opaz_newcycle

    .opaz_absent:
        inc .opaz_ab_c

    .opaz_newcycle:
        sub cx, size Stu
        jge .opaz_cycle

        ; 统计循环结束，显示结果

        lea dx, azmsg_cnt0      ; 总人数
        call print
        mov al, reccount
        xor ah, ah              ; 保留用于计算
        mov si, ax
        mov di, si              ; 用于四舍五入
        shr di, 1
        call putdecal
        lea dx, azmsg_cnt1
        call print

        mov bh, .opaz_ex_c      ; 得优人数
        test bh, bh
        jz .opaz_noex
        lea dx, azmsg_ex
        call .opaz_segcount

    .opaz_noex:
        mov bh, .opaz_gd_c
        test bh, bh
        jz .opaz_nogd
        lea dx, azmsg_gd
        call .opaz_segcount

    .opaz_nogd:
        mov bh, .opaz_md_c
        test bh, bh
        jz .opaz_nomd
        lea dx, azmsg_md
        call .opaz_segcount

    .opaz_nomd:
        mov bh, .opaz_ps_c
        test bh, bh
        jz .opaz_nops
        lea dx, azmsg_ps
        call .opaz_segcount

    .opaz_nops:
        mov bh, .opaz_fl_c
        test bh, bh
        jz .opaz_nofl
        lea dx, azmsg_fl
        call .opaz_segcount

    .opaz_nofl:
        mov bh, .opaz_ab_c
        test bh, bh
        jz .opaz_noab

        lea dx, azmsg_ab
        call .opaz_segcount

        xor ah, ah
        mov al, .opaz_ab_c
        sub si, ax              ; 计算平均分时不考虑缺考

    .opaz_noab:
        lea dx, azmsg_max
        call print
        mov al, .opaz_max
        call putdecal

        lea dx, azmsg_min
        call print
        mov al, .opaz_min
        cmp al, 127
        jne .opaz_minavl
        xor al, al
    .opaz_minavl:
        call putdecal

        lea dx, azmsg_avg
        call print

        test si, si
        jnz .opaz_avgavl
        xor dh, dh              ; 全部缺考时，没有平均成绩可给出
        jmp .opaz_avgdigit

    .opaz_avgavl:
        mov ax, .opaz_sum
        mov bx, 10
        mul bx
        add ax, di
        div si
        div bl
        mov dh, ah
        call putdecal

        mov ah, 02h
        mov dl, '.'
        int 21h

    .opaz_avgdigit:
        mov al, dh
        call putdecal

        lea dx, azmsg_end
        call print
        ret

    .opaz_segcount:
        call print
        mov al, bh
        call putdecal
        mov bh, al
        lea dx, scmsg_prt0
        call print

        xor ah, ah
        mov al, bh
        mov bx, 1000
        mul bx
        add ax, di
        div si
        mov bl, 10
        div bl
        call putdecal

        mov bl, ah
        mov ah, 02h
        mov dl, '.'
        int 21h
        add bl, '0'
        mov dl, bl
        int 21h

        lea dx, scmsg_prt1
        call print
        ret

end Entry