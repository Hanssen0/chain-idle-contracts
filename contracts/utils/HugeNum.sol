// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library HugeNumLib {
    int256 constant DECS = 18;
    int256 constant ONE_N = int256(10) ** uint256(DECS);
    int256 constant NEG_ONE_N = -ONE_N;
    int256 constant DECS_N = DECS * ONE_N;
    int256 constant TEN_N = 10 * ONE_N;
    int256 constant LN_TEN_N =
        2302585092994045684 * (int256(10) ** uint256(DECS - 18));
    int256 constant ONE_P_TWO_N = 12 * (int256(10) ** uint256(DECS - 1));
    int256 constant LN_ONE_P_TWO_N =
        182321556793954600 * (int256(10) ** uint256(DECS - 18));
    int256 constant MAX_EXP = 10 ** 5;
    int256 constant MAX_EXP_N = MAX_EXP * ONE_N;
    int256 constant MAX_EXP_EXP_N = 5 * ONE_N;
    int256 constant PREC_EXP_N = 18 * ONE_N;
    int256 constant NEG_PREC_EXP_N = -PREC_EXP_N;
    int256 constant MAX_PREC_EXP_N = MAX_EXP_EXP_N + PREC_EXP_N;
    int256 constant LOG_10_2 =
        301029995662919568 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_3 =
        477121254719662368 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_4 =
        602059991327940775 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_5 =
        698970004334375752 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_6 =
        778151250382000569 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_7 =
        845098040014161479 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_8 =
        903089986991943361 * (int256(10) ** uint256(DECS - 18));
    int256 constant LOG_10_9 =
        954242509439324737 * (int256(10) ** uint256(DECS - 18));

    struct HugeNum {
        int256 mantissa;
        int256 depth;
        int256 exponent;
    }
    using HugeNumLib for HugeNum;

    function ONE() internal pure returns (HugeNum memory) {
        HugeNum memory one;
        one.mantissa = 1;
        one.depth = 1;
        one.exponent = 0;
        return one;
    }

    function toSci(int256 value) internal pure returns (int256, int256) {
        if (value == 0) {
            return (0, 0);
        }

        int256 sign = value < 0 ? -1 : int256(1);
        unchecked {
            value *= sign;
            int256 expR = 0;
            while (value >= TEN_N) {
                value /= 10;
                expR += ONE_N;
            }
            while (value < ONE_N) {
                value *= 10;
                expR -= ONE_N;
            }

            return (value * sign, expR);
        }
    }

    function lnInt(int256 x) internal pure returns (int256) {
        int256 sign = x < 0 ? -1 : int256(1);
        unchecked {
            x *= sign;

            int256 log = 0;
            while (x >= TEN_N) {
                log = log + LN_TEN_N;
                x = x / 10;
            }
            while (x >= ONE_P_TWO_N) {
                log = log + LN_ONE_P_TWO_N;
                x = (x * 5) / 6;
            }
            x = x - ONE_N;
            int256 y = x;
            int256 i = 1;
            while (i < 13) {
                log = log + y / i;
                i = i + 1;
                y = (y * x) / ONE_N;
                log = log - y / i;
                i = i + 1;
                y = (y * x) / ONE_N;
            }

            return log * sign;
        }
    }

    function log10Int(int256 x) internal pure returns (int256) {
        unchecked {
            return (lnInt(x) * ONE_N) / LN_TEN_N;
        }
    }

    function _tenPow(int256 x) internal pure returns (uint256) {
        unchecked {
            uint256 l = uint256(x / ONE_N);
            int256 r = x - int256(l) * ONE_N;
            if (r < LOG_10_2) {
                return 10 ** l;
            }
            if (r < LOG_10_3) {
                return 10 ** l * 2;
            }
            if (r < LOG_10_4) {
                return 10 ** l * 3;
            }
            if (r < LOG_10_5) {
                return 10 ** l * 4;
            }
            if (r < LOG_10_6) {
                return 10 ** l * 5;
            }
            if (r < LOG_10_7) {
                return 10 ** l * 6;
            }
            if (r < LOG_10_8) {
                return 10 ** l * 7;
            }
            if (r < LOG_10_9) {
                return 10 ** l * 8;
            }
            return 10 ** l * 9;
        }
    }

    function tenPow(int256 x) internal pure returns (int256) {
        if (x == 0) {
            return ONE_N;
        }

        unchecked {
            if (x < PREC_EXP_N) {
                return 0;
            }

            if (x < 0) {
                return ONE_N / int256(_tenPow(-x));
            }

            return ONE_N * int256(_tenPow(x));
        }
    }

    function expSub(
        HugeNum memory a,
        HugeNum memory b
    ) internal pure returns (int256) {
        unchecked {
            int256 depthDiff = a.depth - b.depth;
            if (depthDiff <= -2) {
                return NEG_PREC_EXP_N;
            }
            if (depthDiff >= 2) {
                return PREC_EXP_N;
            }
            int256 aExp = a.exponent;
            int256 bExp = b.exponent;
            if (depthDiff == -1) {
                if (bExp > MAX_PREC_EXP_N) {
                    return NEG_PREC_EXP_N;
                }
                bExp = tenPow(bExp);
            }
            if (depthDiff == 1) {
                if (aExp > MAX_PREC_EXP_N) {
                    return PREC_EXP_N;
                }
                aExp = tenPow(aExp);
            }
            int256 expDiff = aExp - bExp;
            if (expDiff >= PREC_EXP_N) {
                return PREC_EXP_N;
            }
            if (expDiff <= NEG_PREC_EXP_N) {
                return NEG_PREC_EXP_N;
            }
            return expDiff;
        }
    }

    function addExp(HugeNum memory value, int256 expI) internal pure {
        if (expI == 0) {
            return;
        }

        unchecked {
            if (value.depth == 1) {
                value.exponent += expI;
            } else if (value.depth == 2) {
                if (value.exponent <= MAX_PREC_EXP_N) {
                    value.depth = 1;
                    value.exponent = tenPow(value.exponent) + expI;
                }
            }

            if (value.exponent >= MAX_EXP_N) {
                value.depth += 1;
                value.exponent = log10Int(value.exponent);
            }
        }
    }

    function norm(HugeNum memory value) internal pure {
        (int256 mantissa, int256 expR) = toSci(value.mantissa);
        value.mantissa = mantissa;

        value.addExp(expR);
    }

    function normNoM(HugeNum memory value) internal pure {
        value.addExp(log10Int(value.mantissa));
        value.mantissa = 1;
    }

    function exp(HugeNum memory value) internal pure returns (HugeNum memory) {
        HugeNum memory expR;
        if (value.depth == 1) {
            expR.mantissa = value.exponent;
            expR.depth = 1;
            expR.exponent = 0;
            expR.norm();
            return expR;
        }

        expR.mantissa = ONE_N;
        unchecked {
            expR.depth = value.depth - 1;
        }
        expR.exponent = value.exponent;
        return expR;
    }

    function gt(
        HugeNum memory a,
        HugeNum memory b
    ) internal pure returns (bool) {
        if (a.mantissa <= 0) {
            if (b.mantissa >= 0) {
                return false;
            }
        } else if (b.mantissa <= 0) {
            return true;
        }

        unchecked {
            int256 depthDiff = a.depth - b.depth;
            if (depthDiff >= 2) {
                return a.mantissa > 0;
            }
            if (depthDiff <= -2) {
                return a.mantissa <= 0;
            }

            int256 aExp = a.exponent;
            int256 bExp = b.exponent;
            if (depthDiff == 1) {
                if (aExp > MAX_PREC_EXP_N) {
                    return a.mantissa > 0;
                }
                aExp = tenPow(aExp);
            } else if (depthDiff == -1) {
                if (bExp > MAX_PREC_EXP_N) {
                    return a.mantissa <= 0;
                }
                bExp = tenPow(bExp);
            }

            if (aExp == bExp) {
                return a.mantissa > b.mantissa;
            }
            if (a.mantissa > 0) {
                return aExp > bExp;
            }
            return aExp < bExp;
        }
    }

    function _inc(HugeNum memory self, HugeNum memory value) internal pure {
        int256 expSubR = self.expSub(value);
        if (expSubR == PREC_EXP_N) {
            return;
        }
        if (expSubR == NEG_PREC_EXP_N) {
            self.mantissa = value.mantissa;
            self.depth = value.depth;
            self.exponent = value.exponent;
            return;
        }

        unchecked {
            if (expSubR > 0) {
                self.mantissa += (value.mantissa * ONE_N) / tenPow(expSubR);
            } else if (expSubR < 0) {
                self.mantissa =
                    (self.mantissa * ONE_N) /
                    tenPow(-expSubR) +
                    value.mantissa;
                self.depth = value.depth;
                self.exponent = value.exponent;
            } else {
                self.mantissa += value.mantissa;
            }
        }
    }

    function inc(HugeNum memory self, HugeNum memory value) internal pure {
        self._inc(value);
        self.norm();
    }

    function _dec(HugeNum memory self, HugeNum memory value) internal pure {
        value.mantissa = -value.mantissa;
        self._inc(value);
        value.mantissa = -value.mantissa;
    }

    function dec(HugeNum memory self, HugeNum memory value) internal pure {
        value.mantissa = -value.mantissa;
        self.inc(value);
        value.mantissa = -value.mantissa;
    }

    function multiply(HugeNum memory self, HugeNum memory value) internal pure {
        unchecked {
            (int256 mantissa, int256 mExp) = toSci(
                (self.mantissa * value.mantissa) / ONE_N
            );
            self.mantissa = mantissa;

            HugeNum memory expR = self.exp();
            expR._inc(value.exp());
            if (mExp == ONE_N) {
                expR._inc(ONE());
            }

            if (expR.depth == 1 && expR.exponent < MAX_EXP_EXP_N) {
                self.depth = 1;
                self.exponent = (expR.mantissa * tenPow(expR.exponent)) / ONE_N;
            } else {
                expR.normNoM();
                self.depth = expR.depth + 1;
                self.exponent = expR.exponent;
            }

            self.norm();
        }
    }

    function divide(HugeNum memory self, HugeNum memory value) internal pure {
        unchecked {
            (int256 mantissa, int256 mExp) = toSci(
                (self.mantissa * ONE_N) / value.mantissa
            );
            self.mantissa = mantissa;

            HugeNum memory expR = self.exp();
            expR._dec(value.exp());
            if (mExp == NEG_ONE_N) {
                expR._dec(ONE());
            }

            if (expR.depth == 1 && expR.exponent < MAX_EXP_EXP_N) {
                self.depth = 1;
                self.exponent = (expR.mantissa * tenPow(expR.exponent)) / ONE_N;
            } else {
                expR.normNoM();
                self.depth = expR.depth + 1;
                self.exponent = expR.exponent;
            }

            self.norm();
        }
    }
}
