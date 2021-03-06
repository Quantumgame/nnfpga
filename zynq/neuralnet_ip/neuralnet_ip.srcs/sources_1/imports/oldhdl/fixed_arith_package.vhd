library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use work.helperpkg.all;

package nn_arith_package is

-- truncate a longer sfixed value to
-- 16 long in a manner that is
-- safe for neural nets, i.e. setting to
-- max in case carry bits exist
function fun_add_truncate (
    datain: std_logic_vector(16 downto 0)
) return std_logic_vector;

function fun_mul_truncate (
    datain: std_logic_vector(2*16 - 1 downto 0)
) return std_logic_vector;

function func_safe_sum (
    A: std_logic_vector (15 downto 0);
    B: std_logic_vector (15 downto 0)
)return std_logic_vector;

function func_safe_mult (
    A: std_logic_vector (15 downto 0);
    B: std_logic_vector (15 downto 0)
)return std_logic_vector;

end package;


package body nn_arith_package is 

function fun_add_truncate (
    datain: std_logic_vector(16 downto 0)
) return std_logic_vector is
    variable carry:  std_logic;
    variable var_ret: std_logic_vector (16 - 1 downto 0);
    variable sign_bit: std_logic;
    variable top_bit: std_logic;
    variable maxed: std_logic_vector (16 - 1 downto 0);
begin
    sign_bit := datain (16);
    top_bit := datain (16 - 1);
    if (sign_bit = top_bit) then
        carry := '0';
    else
        carry := '1';
    end if;
    
    maxed (16 - 1) := sign_bit; 
    if (sign_bit = '1') then
        maxed (16 - 2 downto 0) := (others => '0');
    else
        maxed (16 - 2 downto 0) := (others => '1');
    end if;

    if (carry = '0') then
        var_ret := datain (16 - 1 downto 0);
    else
        var_ret := maxed; 
    end if;
    return var_ret;
end function;

function fun_mul_truncate (
    datain: std_logic_vector(2*16 - 1 downto 0)
) return std_logic_vector is
    variable carry: std_logic;
    variable var_ret: std_logic_vector (16 - 1 downto 0);
    variable sign_bit: std_logic;
    variable top_bit: std_logic;
    variable maxed: std_logic_vector (16 - 1 downto 0);
begin
    sign_bit := datain (2*16 - 1);
    top_bit  := datain (2*PARAM_FRC + PARAM_DEC - 1);
    --is the multiplication result too large?
    carry := '0';
    for I in 2*PARAM_FRC + PARAM_DEC to 2*16 - 1 loop
        if (datain(I) /= top_bit) then
            carry := '1';
        end if;
    end loop;
    
    maxed (16 - 1) := sign_bit; 
    if (sign_bit = '1') then
        maxed (16 - 2 downto 0) := (others => '0');
    else
        maxed (16 - 2 downto 0) := (others => '1');
    end if;

    if (carry = '0') then
        var_ret := datain (2*PARAM_FRC + PARAM_DEC - 1 downto PARAM_FRC);
    else
        var_ret := maxed;
    end if;

    return var_ret;
end function;

function func_safe_sum (
    A: std_logic_vector (15 downto 0);
    B: std_logic_vector (15 downto 0)
)return std_logic_vector is
    variable A_sfixed: sfixed (PARAM_DEC - 1 downto -PARAM_FRC);
    variable B_sfixed: sfixed (PARAM_DEC - 1 downto -PARAM_FRC);
    variable C_sfixed_full: sfixed (PARAM_DEC downto -PARAM_FRC); 
    variable C_stdvec_full: std_logic_vector (16 downto 0);
    subtype  sum_result_type is std_logic_vector (16 downto 0);
    variable ret: std_logic_vector (15 downto 0);
begin
    A_sfixed := to_sfixed (A, PARAM_DEC - 1, -PARAM_FRC);
    B_sfixed := to_sfixed (B, PARAM_DEC - 1, -PARAM_FRC);
    C_sfixed_full := A_sfixed + B_sfixed; 
    C_stdvec_full := sum_result_type (C_sfixed_full);
    ret := fun_add_truncate (C_stdvec_full);
    return ret;
end function;

function func_safe_mult (
    A: std_logic_vector (15 downto 0);
    B: std_logic_vector (15 downto 0)
)return std_logic_vector is
    variable A_sfixed: sfixed (PARAM_DEC - 1 downto -PARAM_FRC);
    variable B_sfixed: sfixed (PARAM_DEC - 1 downto -PARAM_FRC);
    variable C_sfixed_full: sfixed (2* PARAM_DEC - 1 downto -2* PARAM_FRC); 
    variable C_stdvec_full: std_logic_vector (31 downto 0);
    subtype  mult_result_type is std_logic_vector (31 downto 0); 
    variable ret: std_logic_vector (15 downto 0);
begin
    A_sfixed := to_sfixed (A, PARAM_DEC - 1, -PARAM_FRC);
    B_sfixed := to_sfixed (B, PARAM_DEC - 1, -PARAM_FRC);
    C_sfixed_full := A_sfixed * B_sfixed; 
    C_stdvec_full := mult_result_type (C_sfixed_full);
    ret := fun_mul_truncate (C_stdvec_full);
    return ret;
end function;


end package body;
