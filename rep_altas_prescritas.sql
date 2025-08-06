WITH alta_prescricao AS (
    SELECT
        pm.nr_atendimento,
        pm.dt_prescricao dt_registro,
        'PRESCR RECOMENDAÇÃO'          ds_origem,
        TO_DATE(to_char(pm.dt_prescricao, 'DD/MM/YYYY')
                || ' '
                || pr.hr_prim_horario,
                'DD/MM/YYYY HH24:MI:SS') AS dt_solic_alta,
        sa.cd_setor_atendimento,
        sa.ds_setor_atendimento
    FROM
              tasy.prescr_medica pm
        INNER JOIN tasy.prescr_recomendacao pr ON pm.nr_prescricao = pr.nr_prescricao
        INNER JOIN tasy.atendimento_paciente ap ON pm.nr_atendimento = ap.nr_atendimento
        INNER JOIN tasy.setor_atendimento   sa ON pm.cd_setor_orig = sa.cd_setor_atendimento
    WHERE
            pr.cd_recomendacao = 84
        AND pr.dt_suspensao IS NULL
        AND pm.dt_liberacao IS NOT NULL
        AND pm.dt_suspensao IS NULL
        AND ap.dt_alta IS NULL
        AND sa.cd_classif_setor = 3
        AND sa.cd_setor_atendimento NOT IN (87426, 87609)
        AND pm.dt_validade_prescr > sysdate
), alta_resumo AS (
    SELECT
        er.nr_atendimento,
        er.dt_registro,
        'RESUMO INTERNAÇÃO' ds_origem,
        ere.dt_resultado    dt_solic_alta,
        sa.cd_setor_atendimento,
        sa.ds_setor_atendimento
    FROM
              tasy.ehr_reg_elemento ere
        INNER JOIN tasy.ehr_elemento       ee ON ere.nr_seq_elemento = ee.nr_sequencia
        INNER JOIN tasy.ehr_reg_template   ert ON ere.nr_seq_reg_template = ert.nr_sequencia
        INNER JOIN tasy.ehr_registro       er ON ert.nr_seq_reg = er.nr_sequencia
        INNER JOIN tasy.ehr_template       et ON ert.nr_seq_template = et.nr_sequencia
        INNER JOIN tasy.atendimento_paciente ap ON er.nr_atendimento = ap.nr_atendimento
        INNER JOIN tasy.setor_atendimento    sa ON er.cd_setor_atendimento = sa.cd_setor_atendimento
    WHERE
        et.nr_sequencia IN (100260, 100531)
        AND ere.nr_seq_elemento IN (764, 9005169)
        AND er.dt_liberacao >= sysdate - INTERVAL '72' HOUR
        AND er.dt_inativacao IS NULL
        AND ere.dt_resultado IS NOT NULL
        AND ap.dt_alta IS NULL
        AND sa.cd_classif_setor = 3
        AND sa.cd_setor_atendimento NOT IN (87426, 87609)
), dados_unificados AS (
    SELECT
        *
    FROM
        alta_prescricao
    UNION ALL
    SELECT
        *
    FROM
        alta_resumo
)
SELECT
    nr_atendimento,
    dt_registro,
    ds_origem,
    dt_solic_alta,
    cd_setor_atendimento,
    ds_setor_atendimento
FROM
    dados_unificados