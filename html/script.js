$(document).ready(function() {
    
    function showGridOverlay() {
        if (!$('#grid-overlay').length) {
            $('<div id="grid-overlay"></div>').appendTo('body');
        }
        $('#grid-overlay').fadeIn(200);
    }

    function hideGridOverlay() {
        $('#grid-overlay').fadeOut(200, function() {
            $(this).remove(); 
        });
    }

    function saveAllHUDData() {
        let layoutData = {};
        let styleData = {};
        const globalScale = $('#hud-scale').val();

        const elements = [
        ".server-logo", ".job-wrapper", ".player-id-wrapper", 
        ".money-item", ".gold-item", ".blackmoney-item",
        ".heart-item", ".stamina-item", ".hunger-item", 
        ".thirst-item", ".stress-item", ".alcohol-item", 
        ".temp-item", ".voice-item", ".horseheath-item",
        ".horsestamina-item", 
        ".lumberjack-item",  ".mining-item",  ".hunting-item",
        ".fishing-item",  ".farming-item"
        ];

        elements.forEach(el => {
            const item = $(el);
            if (item.length > 0) {
                let pos = item.offset(); 
                layoutData[el] = {
                    top: pos.top,
                    left: pos.left
                };
            }
        });

        $('.element-row').each(function() {
            const target = $(this).data('target');
            const scale = $(this).find('.el-scale').val();
            const color = $(this).find('.el-color').val();

            styleData[target] = {
                scale: scale,
                color: color
            };
        });

        $.post('https://tpz_advancehud/saveHUDData', JSON.stringify({
            layout: layoutData,
            scale: globalScale,
            styles: styleData 
        }));
    }

    $('.toggle-visible').on('click', function() {
        const btn = $(this);
        const target = btn.closest('.element-row').data('target');
        
        btn.toggleClass('hidden');
        
        if (btn.hasClass('hidden')) {
            $(target).fadeOut(100);
        } else {
            $(target).fadeIn(100);
        }
    });

    $('#master-display').on('click', function() {
        $(this).toggleClass('hidden');
        const isHidden = $(this).hasClass('hidden');
        
        $('#hud-container').css('display', isHidden ? 'none' : 'block');

        $.post('https://tpz_advancehud/toggleMasterDisplay', JSON.stringify({
            visible: !isHidden
        }));
    });

    $('.el-scale').on('input', function() {
        const target = $(this).closest('.element-row').data('target');
        $(target).css('transform', 'scale(' + $(this).val() + ')');
    });

    $('.el-color').on('input', function() {
        const target = $(this).closest('.element-row').data('target');
        const color = $(this).val();
        

        $(target).find('.progress').css('stroke', color); 
        $(target).find('.temp-text').css('color', color);
        $(target).find('span').css('color', color);
    });

    $('#hud-scale').on('input', function() {
        $('#hud-container').css({
            'transform': 'scale(' + $(this).val() + ')',
            'transform-origin': 'top left'
        });
    });

    const dragTargets = [
        ".server-logo", ".job-wrapper", ".player-id-wrapper", 
        ".money-item", ".gold-item", ".blackmoney-item",
        ".heart-item", ".stamina-item", ".hunger-item", 
        ".thirst-item", ".stress-item", ".alcohol-item", 
        ".temp-item", ".voice-item", ".horseheath-item",
        ".horsestamina-item", 
        ".lumberjack-item",  ".mining-item",  ".hunting-item",
        ".fishing-item",  ".farming-item"
    ];

    $('#start-layout').on('click', function() {
        $('#settings-panel').hide();
        $('#save-layout-btn').show();

        showGridOverlay();

        $(dragTargets.join(", ")).each(function() {
            const el = $(this);
            el.draggable({
                enabled: true,
                containment: "window",
                scroll: false,
                start: function(event, ui) {
                    el.css({
                        'transform': 'none', 
                        'bottom': 'auto',
                        'right': 'auto',
                        'margin': '0',
                        'position': 'fixed' 
                    });
                }
            });
            el.css('pointer-events', 'auto'); 
        });
    });

    $('#save-layout-btn').on('click', function() {
        saveAllHUDData(); 
        
        const elements = [
        ".server-logo", ".job-wrapper", ".player-id-wrapper", 
        ".money-item", ".gold-item", ".blackmoney-item",
        ".heart-item", ".stamina-item", ".hunger-item", 
        ".thirst-item", ".stress-item", ".alcohol-item", 
        ".temp-item", ".voice-item", ".horseheath-item",
        ".horsestamina-item", 
        ".lumberjack-item",  ".mining-item",  ".hunting-item",
        ".fishing-item",  ".farming-item"
        ];
        
        elements.forEach(el => {
            if ($(el).hasClass('ui-draggable')) $(el).draggable("destroy");
        });

        hideGridOverlay();
        $(this).hide();
        $.post('https://tpz_advancehud/CloseEdit', JSON.stringify({}));
    });

    $('#close-settings').click(function() {
        saveAllHUDData(); 
        $('#settings-panel').hide();
        $.post('https://tpz_advancehud/CloseEdit', JSON.stringify({}));
    });

    $('#cinematic-btn').on('click', function() {
        $.post('https://tpz_advancehud/toggleCinematic', JSON.stringify({}));
    });

});

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.showhud !== undefined) {
        const isMasterHidden = $('#master-display').hasClass('hidden');
        
        if (data.showhud && !isMasterHidden) {
            $('#hud-container').show();
        } else {
            $('#hud-container').hide();
        }
    }

    if (data.scale) {
        $('#hud-scale').val(data.scale);
        $('#hud-container').css({
            'transform': 'scale(' + data.scale + ')',
            'transform-origin': 'top left'
        });
    }

    if (data.layout) {
        for (const [selector, pos] of Object.entries(data.layout)) {
            $(selector).css({
                'position': 'fixed',
                'top': pos.top + 'px',
                'left': pos.left + 'px',
                'bottom': 'auto',
                'right': 'auto'
            });
        }
    }

    if (data.styles) {
        for (const [target, settings] of Object.entries(data.styles)) {
            const el = $(target);
            if (el.length > 0) {
                el.css('transform', 'scale(' + settings.scale + ')');
        
                el.find('.progress').css('stroke', settings.color);
                el.find('.temp-text').css('color', settings.color);

                const row = $(`.element-row[data-target="${target}"]`);
                row.find('.el-scale').val(settings.scale);
                row.find('.el-color').val(settings.color);
            }
        }
    }

    if (data.action === "openSettings") {
        $('#settings-panel').show();
    }

    if (data.showhud !== undefined) {
        const hudContainer = document.getElementById('hud-container');
        if (hudContainer) hudContainer.style.display = data.showhud ? "block" : "none";
    }

    if (data.serverId !== undefined) {
        const idElement = document.getElementById('player-id-val');
        if (idElement) idElement.innerText = data.serverId;
    }

    if (data.money !== undefined) {
        document.getElementById('cash-val').innerText = "$" + data.money.toLocaleString();
    }
    
    if (data.gold !== undefined) {
        document.getElementById('gold-val').innerText = data.gold;
    }

    const bmBox = document.getElementById('black-money-box');
    if (data.blackMoney !== undefined && data.blackMoney > 0) {
        if(bmBox) bmBox.style.display = 'block';
        document.getElementById('black-val').innerText = data.blackMoney;
    } else {
        if(bmBox) bmBox.style.display = 'none';
    }

    if (data.jobLabel !== undefined) {
        const jobLabelEl = document.getElementById('job-label');
        if (jobLabelEl) jobLabelEl.innerText = data.jobLabel;
    }

    if (data.hp !== undefined) updateCircle('hp', data.hp, 200);
    if (data.stamina !== undefined) updateCircle('stamina', data.stamina, 100);
    if (data.hunger !== undefined) updateCircle('hunger', data.hunger, 100);
    if (data.thirst !== undefined) updateCircle('thirst', data.thirst, 100);
    if (data.alcohol !== undefined) updateCircle('alcohol', data.alcohol, 100, true);
    if (data.stress !== undefined) updateCircle('stress', data.stress, 100, true);

    if (data.temperature) {
        const tempText = document.getElementById('temp-val');

        if (tempText) {
                tempText.innerText = data.temperature;
                tempText.style.color = "#ffffff"; 
        }

        const tempCircle = document.querySelector('.temp-item .bg'); 
        
        if (tempText) tempText.innerText = data.temperature;
        
        if (tempCircle) {
            const tempNum = parseInt(data.temperature);
            let color = "#ffffff"; 

            if (tempNum <= 0) {
                color = "#006eff"; 
            } else if (tempNum > 0 && tempNum <= 10) {
                color = "#85b9fc"; 
            } else if (tempNum > 10 && tempNum <= 22) {
                color = "#f8d17b"; 
            } else if (tempNum > 22 && tempNum <= 35) {
                color = "#eca917"; 
            } else {
                color = "#fd8f00"; 
            }


            tempCircle.style.stroke = color;

        }
    }

if (data.action === "is_talking") {

    const voiceCircle = document.querySelector('.voice-item .bg'); 
    
    let voiceColor = data.talking ? "#ffcf40" : "#4d4d4d8f";

    if (voiceCircle) {
        voiceCircle.style.stroke = voiceColor;
    }
}

if (data.action === "voice_level") {
    updateCircle('voice-level', data.voicelevel * 33.3, 100);
}

    if (data.showHorse !== undefined) {
        const horseHpBox = document.getElementById('horse-hp-box');
        const horseStaminaBox = document.getElementById('horse-stamina-box');
        
        if (data.showHorse) {
            if(horseHpBox) horseHpBox.style.display = 'flex';
            if(horseStaminaBox) horseStaminaBox.style.display = 'flex';
            if (data.horsehealth !== undefined) updateCircle('horsehealth', data.horsehealth, 100);
            if (data.horsestamina !== undefined) updateCircle('horsestamina', data.horsestamina, 100);
        } else {
            if(horseHpBox) horseHpBox.style.display = 'none';
            if(horseStaminaBox) horseStaminaBox.style.display = 'none';
        }
    }


    if (data.levelingConfig !== undefined) {
        if (data.levelingConfig && data.levels) {
            $('#leveling-settings-group').show();

            for (const [skillName, skillData] of Object.entries(data.levels)) {
                $(`#${skillName}-item`).show();


                const levelEl = document.getElementById(skillName + '-level');
                if (levelEl) levelEl.innerText = skillData.level;


                updateCircle(skillName + '-progress', skillData.experience, 100);
            }
        } else {
            $('#leveling-settings-group').hide();
            $('.lumberjack-item, .mining-item, .hunting-item, .fishing-item, .farming-item').hide();
        }
    }
 
});

function updateCircle(id, value, max, reverse) {
    const circle = document.getElementById(id);
    if (!circle) return;
    
    const circumference = 125; 
    const percentage = Math.min(Math.max(value / max, 0), 1);
    
    if (reverse) {
        circle.style.strokeDashoffset = circumference * (1 - percentage);
    } else {
        circle.style.strokeDashoffset = circumference - (percentage * circumference);
    }


    const parent = $(circle).closest('.hud-item');
    const parentId = parent.attr('id'); 
    const savedColor = $(`.element-row[data-target="#${parentId}"]`).find('.el-color').val();
    
    if (savedColor) {
        circle.style.stroke = savedColor;
        circle.style.fill = "none"; 
    }
}